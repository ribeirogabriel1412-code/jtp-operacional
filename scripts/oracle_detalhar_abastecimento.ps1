# Detalha as tabelas de Abastecimento/Km-L encontradas na exploracao anterior
# (prefixo ABA_* no Oracle, achado por coincidencia nos padroes CODIGOVEIC/PREFIXO).
#
# RODAR NO SERVIDOR. Senha vem de $env:JTP_ORACLE_PWD (setar antes, nunca colar aqui).

$DSN = "GLOBUSSERVER"
$UID = if ($env:JTP_ORACLE_UID) { $env:JTP_ORACLE_UID } else { "CONSULTA868" }
$PWD_ORACLE = if ($env:JTP_ORACLE_PWD) { $env:JTP_ORACLE_PWD } else { "COLE_AQUI" }
$OUT_FILE = "C:\sync_praxio\relatorios\detalhe_abastecimento.txt"

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
$conn.Open()
Log "Conectado -- $(Get-Date)"

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
            # GetValue pode falhar em tipos Oracle especiais (ex: TIMESTAMP invalido) --
            # protege por coluna em vez de deixar a linha inteira falhar.
            try {
                $val = $reader.GetValue($c)
                if ($val -is [DBNull]) { $val = $null }
            } catch {
                $val = "<erro leitura>"
            }
            $obj[$colNames[$c]] = $val
        }
        $resultados.Add([PSCustomObject]$obj)
    }
    $reader.Close()
    return $resultados
}

# -- Passo 1: busca ampla por qualquer tabela com cara de abastecimento/combustivel/km --
Log ""
Log "========================================================"
Log "Busca ampla: tabelas com colunas de litro/combustivel/abastecimento/km"
Log "========================================================"
$padroes = @("%LITRO%", "%COMBUST%", "%ABAST%", "%TANQUE%", "%KM%")
$candidatas = @{}
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
    }
}
$ordenadas = $candidatas.GetEnumerator() | Sort-Object { $_.Value.Count } -Descending
Log ""
Log "Tabelas candidatas (top 40, ordenadas por qtd de colunas batidas):"
foreach ($item in (@($ordenadas) | Select-Object -First 40)) {
    Log "  $($item.Key) -- colunas: $($item.Value -join ', ')"
}

# -- Passo 2: detalhe completo das tabelas ABA_* ja identificadas manualmente --------
$tabelas = @(
    "GLOBUS868.ABA_REL_PREFIXOPORLITROS",
    "GLOBUS868.ABA_REL_PREFIXOKM",
    "GLOBUS868.VWABA_CONSMEDCAR",
    "GLOBUS868.VWABA_CONSCOMBREPVEICHORA",
    "GLOBUS868.ABA_ITEMABASTCARRO",
    "GLOBUS868.ABA_MOVTANQUE",
    "GLOBUS868.AUX_REL_ABASTECIMENTO"
)

Log ""
Log "========================================================"
Log "Detalhe completo das tabelas de Abastecimento"
Log "========================================================"
foreach ($t in $tabelas) {
    $partes = $t -split '\.', 2
    $owner = $partes[0]; $nome = $partes[1]
    Log ""
    Log "--- $t ---"
    try {
        $cols = Roda-Query "SELECT COLUMN_NAME, DATA_TYPE, DATA_LENGTH FROM ALL_TAB_COLUMNS WHERE OWNER = '$owner' AND TABLE_NAME = '$nome' ORDER BY COLUMN_ID"
        if ($cols.Count -eq 0) { Log "(tabela nao encontrada)"; continue }
        $colunas = @()
        foreach ($c in $cols) { $colunas += "$($c.COLUMN_NAME) ($($c.DATA_TYPE)/$($c.DATA_LENGTH))" }
        Log "Colunas ($($cols.Count)): $($colunas -join ', ')"
    } catch {
        Log "  (falha ao ler colunas: $($_.Exception.Message))"
        continue
    }
    try {
        $amostra = Roda-Query "SELECT * FROM $t WHERE ROWNUM <= 10" 30
        Log "Amostra (ate 10 linhas):"
        Log ($amostra | Format-Table -AutoSize | Out-String -Width 300)
    } catch {
        Log "  (falha ao ler amostra: $($_.Exception.Message))"
    }
    try {
        $qtd = Roda-Query "SELECT COUNT(*) AS QTD FROM $t" 60
        Log "Contagem total de linhas: $($qtd[0].QTD)"
    } catch {
        Log "  (falha ao contar linhas: $($_.Exception.Message))"
    }
}

$conn.Close()
Log ""
Log "Concluido em $(Get-Date). Arquivo salvo em: $OUT_FILE"
