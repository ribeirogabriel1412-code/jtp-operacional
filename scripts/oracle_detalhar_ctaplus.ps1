# Detalha os melhores candidatos pra fonte completa do CTAPLUS/abastecimento no Oracle.
# RODAR NO SERVIDOR. Senha vem de $env:JTP_ORACLE_PWD.

$DSN = "GLOBUSSERVER"
$UID = if ($env:JTP_ORACLE_UID) { $env:JTP_ORACLE_UID } else { "CONSULTA868" }
$PWD_ORACLE = if ($env:JTP_ORACLE_PWD) { $env:JTP_ORACLE_PWD } else { "COLE_AQUI" }
$OUT_FILE = "C:\sync_praxio\relatorios\detalhe_ctaplus.txt"

$connStr = "DSN=$DSN;UID=$UID;PWD=$PWD_ORACLE"
New-Item -ItemType Directory -Path (Split-Path $OUT_FILE) -Force | Out-Null
if (Test-Path $OUT_FILE) { Remove-Item $OUT_FILE -Force }
function Log($t) { Write-Host $t; Add-Content -Path $OUT_FILE -Value $t -Encoding UTF8 }

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
            try { $val = $reader.GetValue($c); if ($val -is [DBNull]) { $val = $null } }
            catch { $val = "<erro leitura>" }
            $obj[$colNames[$c]] = $val
        }
        $resultados.Add([PSCustomObject]$obj)
    }
    $reader.Close()
    return $resultados
}

$tabelas = @(
    "GLOBUS868.PI_ABA",
    "GLOBUS868.ABA_IMPORT_CTAPLUS_TMP",
    "GLOBUS868.VW_LANCAMENTOABASTECIMENTO",
    "GLOBUS868.VWCGS_ABASTECIMENTOS",
    "GLOBUS868.MBL_ABAST_VELOCIMETRO"
)

foreach ($t in $tabelas) {
    $partes = $t -split '\.', 2
    $owner = $partes[0]; $nome = $partes[1]
    Log ""
    Log "========================================================"
    Log "--- $t ---"
    Log "========================================================"
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
        $amostra = Roda-Query "SELECT * FROM (SELECT * FROM $t ORDER BY 1 DESC) WHERE ROWNUM <= 10" 30
        Log "Amostra (ate 10 linhas):"
        Log ($amostra | Format-Table -AutoSize | Out-String -Width 300)
    } catch {
        Log "  (falha ao ler amostra ordenada, tentando sem ordenar: $($_.Exception.Message))"
        try {
            $amostra = Roda-Query "SELECT * FROM $t WHERE ROWNUM <= 10" 30
            Log "Amostra (ate 10 linhas, sem ordenar):"
            Log ($amostra | Format-Table -AutoSize | Out-String -Width 300)
        } catch {
            Log "  (falha tambem sem ordenar: $($_.Exception.Message))"
        }
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
