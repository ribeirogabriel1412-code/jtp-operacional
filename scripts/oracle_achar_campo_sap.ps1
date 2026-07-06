# Descobre qual campo da Oracle corresponde ao "cod_sap" usado no app (codigo
# de 8 digitos tipo 30016636). CODIGOMATINT nao e isso -- e um codigo interno
# curto (confirmado em 2026-07-06, comparando com requisicoes_compra do app).
# RODAR NO SERVIDOR. Senha vem de $env:JTP_ORACLE_PWD.

$DSN = "GLOBUSSERVER"
$UID = if ($env:JTP_ORACLE_UID) { $env:JTP_ORACLE_UID } else { "CONSULTA868" }
$PWD_ORACLE = if ($env:JTP_ORACLE_PWD) { $env:JTP_ORACLE_PWD } else { "COLE_AQUI" }

Add-Type -AssemblyName System.Data
$conn = New-Object System.Data.Odbc.OdbcConnection
$conn.ConnectionString = "DSN=$DSN;UID=$UID;PWD=$PWD_ORACLE"
$conn.Open()
Write-Host "Conectado -- $(Get-Date)" -ForegroundColor Green

function Roda-Query($sql, $timeout = 60) {
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = $sql
    $cmd.CommandTimeout = $timeout
    $reader = $cmd.ExecuteReader()
    try {
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
        return $resultados
    } finally {
        if (-not $reader.IsClosed) { $reader.Close() }
    }
}

Write-Host ""
Write-Host "=== 1) Colunas de EST_CADMATERIAL ===" -ForegroundColor Yellow
$cols = Roda-Query "SELECT COLUMN_NAME, DATA_TYPE FROM ALL_TAB_COLUMNS WHERE OWNER='GLOBUS868' AND TABLE_NAME='EST_CADMATERIAL' ORDER BY COLUMN_ID"
foreach ($c in $cols) { Write-Host "  $($c.COLUMN_NAME) -- $($c.DATA_TYPE)" }

Write-Host ""
Write-Host "=== 2) Linha completa do material CODIGOMATINT=1968 (REBITE LONA DE FREIO, cod_sap esperado 30001845) ===" -ForegroundColor Yellow
$r = Roda-Query "SELECT * FROM GLOBUS868.EST_CADMATERIAL WHERE CODIGOMATINT=1968"
foreach ($linha in $r) {
    foreach ($prop in $linha.PSObject.Properties) {
        Write-Host "    $($prop.Name) = $($prop.Value)"
    }
}

Write-Host ""
Write-Host "=== 3) Procura o valor 30001845 em qualquer coluna de EST_CADMATERIAL (pra achar onde o cod_sap mora) ===" -ForegroundColor Yellow
foreach ($c in $cols) {
    $colName = $c.COLUMN_NAME
    try {
        $test = Roda-Query "SELECT COUNT(*) AS QTD FROM GLOBUS868.EST_CADMATERIAL WHERE TO_CHAR($colName) = '30001845'" 20
        if ($test[0].QTD -gt 0) { Write-Host "  ACHOU em $colName -- $($test[0].QTD) linha(s)" -ForegroundColor Green }
    } catch {}
}

$conn.Close()
Write-Host ""
Write-Host "Concluido em $(Get-Date)." -ForegroundColor Green
