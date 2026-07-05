# Investiga o campo SOS (nunca explorado) e testa filtro SEQ=1 pra ver se
# aproxima o total do PI_MAN dos 65 reais do painel oficial de Pendencias de OS.
# RODAR NO SERVIDOR. Senha vem de $env:JTP_ORACLE_PWD.

$DSN = "GLOBUSSERVER"
$UID = if ($env:JTP_ORACLE_UID) { $env:JTP_ORACLE_UID } else { "CONSULTA868" }
$PWD_ORACLE = if ($env:JTP_ORACLE_PWD) { $env:JTP_ORACLE_PWD } else { "COLE_AQUI" }
$OUT_FILE = "C:\sync_praxio\relatorios\investigar_sos.txt"

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

$whereBase = @"
WHERE FILIAL LIKE '%PORTO VELHO%'
  AND DATA_OS >= TO_DATE('2026-06-01','YYYY-MM-DD')
  AND DATA_OS <  TO_DATE('2026-07-01','YYYY-MM-DD')
"@

Log ""
Log "=== Distribuicao do campo SOS (nunca explorado) ==="
$r1 = Roda-Query "SELECT SOS, COUNT(*) AS QTD FROM GLOBUS868.PI_MAN $whereBase GROUP BY SOS"
$r1 | Format-Table -AutoSize | Out-String -Width 200 | ForEach-Object { Log $_ }

Log ""
Log "=== Distribuicao de TIPOOS ==="
$r2 = Roda-Query "SELECT TIPOOS, COUNT(*) AS QTD, COUNT(DISTINCT CODINTOS) AS QTD_OS FROM GLOBUS868.PI_MAN $whereBase GROUP BY TIPOOS"
$r2 | Format-Table -AutoSize | Out-String -Width 200 | ForEach-Object { Log $_ }

Log ""
Log "=== Teste: filtrando so SEQ = 1 (1a linha de cada OS) ==="
$r3 = Roda-Query "SELECT COUNT(DISTINCT CODINTOS) AS QTD_OS, COUNT(*) AS TOTAL FROM GLOBUS868.PI_MAN $whereBase AND SEQ = 1"
Log "Qtd OS (SEQ=1): $($r3[0].QTD_OS) | Total linhas: $($r3[0].TOTAL)"

Log ""
Log "=== Teste: so onde ORIGEM = GARAGEM (maior grupo do Excel oficial) ==="
$r4 = Roda-Query "SELECT COUNT(DISTINCT CODINTOS) AS QTD_OS FROM GLOBUS868.PI_MAN $whereBase AND ORIGEM = 'GARAGEM' AND SEQ = 1"
Log "Qtd OS (ORIGEM=GARAGEM, SEQ=1): $($r4[0].QTD_OS)"

Log ""
Log "=== Distribuicao de ORIGEM (pra comparar com Excel: GARAGEM 40, RECOLHA ANORMAL 13, RECOLHA NORMAL 13, RECOLHA OPERACIONAL 2, SOCORRO 1) ==="
$r5 = Roda-Query "SELECT ORIGEM, COUNT(DISTINCT CODINTOS) AS QTD_OS FROM GLOBUS868.PI_MAN $whereBase GROUP BY ORIGEM"
$r5 | Format-Table -AutoSize | Out-String -Width 200 | ForEach-Object { Log $_ }

$conn.Close()
Log ""
Log "Concluido em $(Get-Date). Arquivo salvo em: $OUT_FILE"
