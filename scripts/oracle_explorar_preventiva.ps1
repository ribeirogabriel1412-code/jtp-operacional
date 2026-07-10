# Explorador de Schema Oracle -- PRAXIO / Painel "Cumprimento de Revisao"
# Objetivo: achar a tabela/view fonte do relatorio MAN que hoje e importado
# manualmente em PDF no Painel Preventivas (ferr-prev, index.html). Esse PDF
# tem por linha: carro, plano, GRUPO DE REVISAO, KM da ultima execucao,
# qtd de execucoes, KM atual, KM da proxima execucao, KM percorrido desde a
# ultima, EXCESSO de KM, EXCESSO de dias, pendente (sim/nao) -- ver
# parsearMANPreventiva() no index.html (~linha 14793) pros nomes exatos dos
# campos que estamos tentando casar.
#
# O Oracle desse servidor tem ~7000 tabelas (banco corporativo inteiro, nao so
# manutencao) -- entao NAO vasculhamos tabela por tabela. Buscamos direto no
# dicionario de dados (ALL_TAB_COLUMNS/ALL_TABLES/ALL_VIEWS) por padroes
# genericos (peso baixo) e especificos dos campos acima (peso alto), e
# tambem pelo NOME da tabela/view.
#
# RODAR NO SERVIDOR (unico lugar com IP liberado no ODBC GLOBUSSERVER).
#
# A senha real vem de $env:JTP_ORACLE_PWD (setar antes de rodar, nunca colar aqui).

$DSN = "GLOBUSSERVER"
$UID = if ($env:JTP_ORACLE_UID) { $env:JTP_ORACLE_UID } else { "CONSULTA868" }
$PWD_ORACLE = if ($env:JTP_ORACLE_PWD) { $env:JTP_ORACLE_PWD } else { "COLE_AQUI" }
$OUT_FILE = "C:\sync_praxio\relatorios\mapa_oracle_manutencao.txt"

$connStr = "DSN=$DSN;UID=$UID;PWD=$PWD_ORACLE"

New-Item -ItemType Directory -Path (Split-Path $OUT_FILE) -Force | Out-Null
if (Test-Path $OUT_FILE) { Remove-Item $OUT_FILE -Force }

function Log($texto) {
    Write-Host $texto
    Add-Content -Path $OUT_FILE -Value $texto -Encoding UTF8
}

Add-Type -AssemblyName System.Data
$conn = New-Object System.Data.Odbc.OdbcConnection
$conn.ConnectionString = $connStr

try {
    $conn.Open()
    Log "Conectado ao Oracle ($DSN) como $UID -- $(Get-Date)"
} catch {
    Write-Host "ERRO ao conectar: $_" -ForegroundColor Red
    exit 1
}

# Le com OdbcDataReader puro e devolve uma lista de PSCustomObject -- evita
# de vez a ambiguidade do indexador de DataRow no PowerShell.
function Roda-Query($sql, $timeout = 60) {
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = $sql
    $cmd.CommandTimeout = $timeout
    $reader = $cmd.ExecuteReader()
    $colCount = $reader.FieldCount
    $colNames = @()
    for ($c = 0; $c -lt $colCount; $c++) { $colNames += $reader.GetName($c) }

    $resultados = [System.Collections.Generic.List[object]]::new()
    while ($reader.Read()) {
        $obj = [ordered]@{}
        for ($c = 0; $c -lt $colCount; $c++) {
            $val = $reader.GetValue($c)
            if ($val -is [DBNull]) { $val = $null }
            $obj[$colNames[$c]] = $val
        }
        $resultados.Add([PSCustomObject]$obj)
    }
    $reader.Close()
    return $resultados
}

# -- Busca tabelas cujas colunas batem com nomes reais ja confirmados no Oracle --
# Padroes GENERICOS (pesam pouco -- toda tabela de veiculo/OS tem isso, sozinhos nao provam nada)
$padroesGenericos = @(
    "%CODIGOVEIC%", "%PREFIXO%", "%GARAGEM%", "%STATUS%", "%CONDICAO%"
)
# Padroes ESPECIFICOS -- sao os campos que o PDF "Cumprimento de Revisao" realmente
# mostra por veiculo/plano (kmUltima, execucoes, kmAtual, proximaExecucao,
# kmPercorridoUltima, excessoKm, excessoDias, "Grupo de revisao"). Uma tabela com
# QUALQUER um desses e muito mais provavel de ser a fonte real do painel do que
# uma que so tem PREFIXO/GARAGEM/STATUS (que 100+ tabelas do PRAXIO tem).
$padroesEspecificos = @(
    "%REVIS%", "%PREVENT%", "%PLANOMAN%", "%PLANOREV%", "%GRUPOREV%",
    "%EXCESSO%", "%PROXIM%", "%KMULT%", "%KMATUAL%", "%KMPROX%",
    "%DATAULT%", "%ULTEXEC%", "%QTDEXEC%", "%INTERVALOKM%", "%PERIODICID%"
)

Log ""
Log "========================================================"
Log "Tabelas com colunas parecidas ao painel 'Cumprimento de Revisao'"
Log "========================================================"

$candidatas = @{}       # "OWNER.TABLE" -> lista de colunas batidas (generico + especifico)
$pesoEspecifico = @{}   # "OWNER.TABLE" -> quantas colunas ESPECIFICAS bateram

foreach ($p in $padroesGenericos) {
    try {
        $sql = "SELECT OWNER, TABLE_NAME, COLUMN_NAME FROM ALL_TAB_COLUMNS WHERE COLUMN_NAME LIKE '$p'"
        $linhas = Roda-Query $sql
        Log "Padrao generico '$p': $($linhas.Count) colunas encontradas"
        foreach ($linha in $linhas) {
            $chave = "$($linha.OWNER).$($linha.TABLE_NAME)"
            if (-not $candidatas.ContainsKey($chave)) { $candidatas[$chave] = @() }
            $candidatas[$chave] += $linha.COLUMN_NAME
        }
    } catch {
        Log "Padrao '$p' falhou: $($_.Exception.Message)"
        if ($_.Exception.InnerException) { Log "  Detalhe interno: $($_.Exception.InnerException.Message)" }
    }
}

foreach ($p in $padroesEspecificos) {
    try {
        $sql = "SELECT OWNER, TABLE_NAME, COLUMN_NAME FROM ALL_TAB_COLUMNS WHERE COLUMN_NAME LIKE '$p'"
        $linhas = Roda-Query $sql
        Log "Padrao ESPECIFICO '$p': $($linhas.Count) colunas encontradas"
        foreach ($linha in $linhas) {
            $chave = "$($linha.OWNER).$($linha.TABLE_NAME)"
            if (-not $candidatas.ContainsKey($chave)) { $candidatas[$chave] = @() }
            $candidatas[$chave] += $linha.COLUMN_NAME
            if (-not $pesoEspecifico.ContainsKey($chave)) { $pesoEspecifico[$chave] = 0 }
            $pesoEspecifico[$chave] += 1
        }
    } catch {
        Log "Padrao '$p' falhou: $($_.Exception.Message)"
        if ($_.Exception.InnerException) { Log "  Detalhe interno: $($_.Exception.InnerException.Message)" }
    }
}

# Tambem busca pelo NOME da tabela/view (nao so das colunas) -- a tabela fonte do
# painel de revisao provavelmente tem REVIS/PREVENT/PLANO no proprio nome.
Log ""
Log "Tabelas/views cujo NOME contem REVIS/PREVENT/PLANOMAN:"
try {
    $porNome = Roda-Query "SELECT OWNER, TABLE_NAME FROM ALL_TABLES WHERE TABLE_NAME LIKE '%REVIS%' OR TABLE_NAME LIKE '%PREVENT%' OR TABLE_NAME LIKE '%PLANOMAN%' UNION SELECT OWNER, VIEW_NAME AS TABLE_NAME FROM ALL_VIEWS WHERE VIEW_NAME LIKE '%REVIS%' OR VIEW_NAME LIKE '%PREVENT%' OR VIEW_NAME LIKE '%PLANOMAN%'"
    foreach ($t in $porNome) {
        $chave = "$($t.OWNER).$($t.TABLE_NAME)"
        Log "  $chave"
        if (-not $candidatas.ContainsKey($chave)) { $candidatas[$chave] = @('(achada pelo nome da tabela)') }
        if (-not $pesoEspecifico.ContainsKey($chave)) { $pesoEspecifico[$chave] = 0 }
        $pesoEspecifico[$chave] += 5   # nome bater e forte indicio, pesa mais que 1 coluna
    }
} catch {
    Log "  Busca por nome falhou: $($_.Exception.Message)"
}

# Ordena por PESO ESPECIFICO primeiro (o que realmente distingue a tabela certa),
# desempate por quantidade total de colunas batidas.
$ordenadas = $candidatas.GetEnumerator() | Sort-Object -Property `
    @{Expression={ if ($pesoEspecifico.ContainsKey($_.Key)) { $pesoEspecifico[$_.Key] } else { 0 } }; Descending=$true}, `
    @{Expression={ $_.Value.Count }; Descending=$true}

Log ""
Log "Tabelas candidatas (ordenadas por peso especifico, depois qtd de colunas batidas):"
foreach ($item in $ordenadas) {
    $peso = if ($pesoEspecifico.ContainsKey($item.Key)) { $pesoEspecifico[$item.Key] } else { 0 }
    Log "  $($item.Key) [peso especifico=$peso] -- colunas: $($item.Value -join ', ')"
}

if (@($ordenadas).Count -eq 0) {
    Log ""
    Log "NENHUMA tabela encontrada com esses padroes. Talvez os nomes de coluna"
    Log "reais sejam diferentes. Nesse caso, me avise para tentar padroes diferentes."
} else {
    # -- Para as top 10 candidatas, mostra TODAS as colunas + amostra de linhas --
    Log ""
    Log "========================================================"
    Log "Detalhe das top 10 candidatas"
    Log "========================================================"
    $top8 = @($ordenadas) | Select-Object -First 10
    foreach ($item in $top8) {
        $partes = $item.Key -split '\.', 2
        $owner = $partes[0]; $nome = $partes[1]
        Log ""
        Log "--- $owner.$nome ---"
        try {
            $cols = Roda-Query "SELECT COLUMN_NAME, DATA_TYPE FROM ALL_TAB_COLUMNS WHERE OWNER = '$owner' AND TABLE_NAME = '$nome' ORDER BY COLUMN_ID"
            $colunas = @()
            foreach ($c in $cols) { $colunas += "$($c.COLUMN_NAME) ($($c.DATA_TYPE))" }
            Log "Todas as colunas: $($colunas -join ', ')"
        } catch {
            Log "  (falha ao ler colunas: $($_.Exception.Message))"
            continue
        }
        try {
            $amostra = Roda-Query "SELECT * FROM $owner.$nome WHERE ROWNUM <= 10" 30
            Log "Amostra (ate 10 linhas):"
            Log ($amostra | Format-Table -AutoSize | Out-String -Width 300)
        } catch {
            Log "  (falha ao ler amostra: $($_.Exception.Message))"
        }
    }
}

$conn.Close()
Log ""
Log "Concluido em $(Get-Date). Arquivo salvo em: $OUT_FILE"
