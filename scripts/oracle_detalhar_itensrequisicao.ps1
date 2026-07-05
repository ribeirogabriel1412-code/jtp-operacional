# Detalha EST_ITENSREQUISICAO (ja conhecida do sync_praxio.ps1 -- usada na Fase 3
# pra atualizar custo_real em ocorrencias_22) -- ver se bate com o Excel de
# custo/SAP que Daniel exportou (DATA, CODIGO, DESCRICAO, QTD, TOTAL, PREFIXO).
# RODAR NO SERVIDOR. Senha vem de $env:JTP_ORACLE_PWD.

$DSN = "GLOBUSSERVER"
$UID = if ($env:JTP_ORACLE_UID) { $env:JTP_ORACLE_UID } else { "CONSULTA868" }
$PWD_ORACLE = if ($env:JTP_ORACLE_PWD) { $env:JTP_ORACLE_PWD } else { "COLE_AQUI" }
$OUT_FILE = "C:\sync_praxio\relatorios\detalhe_itensrequisicao.txt"

$connStr = "DSN=$DSN;UID=$UID;PWD=$PWD_ORACLE"
New-Item -ItemType Directory -Path (Split-Path $OUT_FILE) -Force | Out-Null
if (Test-Path $OUT_FILE) { Remove-Item $OUT_FILE -Force }
function Log($t) { Write-Host $t; Add-Content -Path $OUT_FILE -Value $t -Encoding UTF8 }

Add-Type -AssemblyName System.Data
$conn = New-Object System.Data.Odbc.OdbcConnection
$conn.ConnectionString = $connStr
$conn.Open()
Log "Conectado -- $(Get-Date)"

function Roda-Query($sql, $timeout = 120) {
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
            catch { $val = $null }
            $obj[$colNames[$c]] = $val
        }
        $resultados.Add([PSCustomObject]$obj)
    }
    $reader.Close()
    return $resultados
}

foreach ($owner in @("GLOBUS868","CONSULTA868")) {
    $t = "$owner.EST_ITENSREQUISICAO"
    Log ""
    Log "--- $t ---"
    try {
        $cols = Roda-Query "SELECT COLUMN_NAME, DATA_TYPE, DATA_LENGTH FROM ALL_TAB_COLUMNS WHERE OWNER = '$owner' AND TABLE_NAME = 'EST_ITENSREQUISICAO' ORDER BY COLUMN_ID"
        if ($cols.Count -eq 0) { Log "(tabela nao encontrada)"; continue }
        $colunas = @()
        foreach ($c in $cols) { $colunas += "$($c.COLUMN_NAME) ($($c.DATA_TYPE)/$($c.DATA_LENGTH))" }
        Log "Colunas ($($cols.Count)): $($colunas -join ', ')"
    } catch {
        Log "  (falha ao ler colunas: $($_.Exception.Message))"
        continue
    }
    try {
        $amostra = Roda-Query @"
SELECT * FROM (SELECT * FROM $t ORDER BY 1 DESC) WHERE ROWNUM <= 10
"@ 30
        Log "Amostra (ate 10 linhas, mais recentes por 1a coluna):"
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
