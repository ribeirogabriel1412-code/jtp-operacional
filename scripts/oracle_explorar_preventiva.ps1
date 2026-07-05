# Explorador de Schema Oracle -- PRAXIO / Painel "Cumprimento de Revisao"
# O Oracle desse servidor tem ~7000 tabelas (banco corporativo inteiro, nao so
# manutencao) -- entao NAO vasculhamos tabela por tabela. Em vez disso, buscamos
# direto no dicionario de dados (ALL_TAB_COLUMNS) por tabelas que tenham colunas
# com nomes parecidos aos que ja vimos em tabelas reais (CODIGOVEIC, PREFIXO_ATUAL,
# DATA_INICIO, DATA_FIM, PREFIXO_OS, EMPRESA) e ao painel oficial de revisao.
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
$padroes = @(
    "%CODIGOVEIC%", "%PREFIXO%", "%DATA_INICIO%", "%DATA_FIM%",
    "%REVIS%", "%PREVENT%", "%GARAGEM%", "%STATUS%", "%CONDICAO%"
)

Log ""
Log "========================================================"
Log "Tabelas com colunas parecidas ao painel 'Cumprimento de Revisao'"
Log "========================================================"

$candidatas = @{}  # "OWNER.TABLE" -> lista de colunas batidas

foreach ($p in $padroes) {
    try {
        $sql = "SELECT OWNER, TABLE_NAME, COLUMN_NAME FROM ALL_TAB_COLUMNS WHERE COLUMN_NAME LIKE '$p'"
        $linhas = Roda-Query $sql
        Log "Padrao '$p': $($linhas.Count) colunas encontradas"
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

# Ordena por quantidade de colunas batidas (a tabela certa deve ter varias, nao so 1)
$ordenadas = $candidatas.GetEnumerator() | Sort-Object { $_.Value.Count } -Descending

Log ""
Log "Tabelas candidatas (ordenadas por qtd de colunas batidas):"
foreach ($item in $ordenadas) {
    Log "  $($item.Key) -- colunas: $($item.Value -join ', ')"
}

if (@($ordenadas).Count -eq 0) {
    Log ""
    Log "NENHUMA tabela encontrada com esses padroes. Talvez os nomes de coluna"
    Log "reais sejam diferentes. Nesse caso, me avise para tentar padroes diferentes."
} else {
    # -- Para as top 8 candidatas, mostra TODAS as colunas + amostra de linhas --
    Log ""
    Log "========================================================"
    Log "Detalhe das top 8 candidatas"
    Log "========================================================"
    $top8 = @($ordenadas) | Select-Object -First 8
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
