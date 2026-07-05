# Valida PI_MAN (deduplicado por CODINTOS) contra o Excel real de
# "Cumprimento de Revisao - Preventiva Pesada" (PVH, junho/2026, 28 registros).
# RODAR NO SERVIDOR. Senha vem de $env:JTP_ORACLE_PWD.

$DSN = "GLOBUSSERVER"
$UID = if ($env:JTP_ORACLE_UID) { $env:JTP_ORACLE_UID } else { "CONSULTA868" }
$PWD_ORACLE = if ($env:JTP_ORACLE_PWD) { $env:JTP_ORACLE_PWD } else { "COLE_AQUI" }
$OUT_FILE = "C:\sync_praxio\relatorios\validar_preventiva_pesada.txt"

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

Log ""
Log "=== PI_MAN deduplicado por CODINTOS -- TIPOOS = CORRETIVA, PVH, junho/2026 ==="
$sql = @"
SELECT CODINTOS, MIN(NUMERO_OS) AS NUMERO_OS, MIN(PREFIXO_VEIC) AS PREFIXO_VEIC,
       MIN(DATA_OS) AS DATA_OS, MAX(CONDICAO_OS) AS CONDICAO_OS,
       MIN(GRUPO_DEFEITO) AS GRUPO_DEFEITO, MIN(DEFEITO) AS DEFEITO
FROM GLOBUS868.PI_MAN
WHERE FILIAL LIKE '%PORTO VELHO%'
  AND DATA_OS >= TO_DATE('2026-06-01','YYYY-MM-DD')
  AND DATA_OS <  TO_DATE('2026-07-01','YYYY-MM-DD')
  AND TIPOOS = 'CORRETIVA'
GROUP BY CODINTOS
"@
$r = Roda-Query $sql 60
Log "Total OS corretivas unicas: $($r.Count)"
Log ""
Log "Distribuicao por CONDICAO_OS:"
$r | Group-Object CONDICAO_OS | ForEach-Object { Log "  $($_.Name): $($_.Count)" }
Log ""
Log "Top 10 GRUPO_DEFEITO:"
$r | Group-Object GRUPO_DEFEITO | Sort-Object Count -Descending | Select-Object -First 10 | ForEach-Object { Log "  $($_.Name): $($_.Count)" }

$conn.Close()
Log ""
Log "Concluido em $(Get-Date). Arquivo salvo em: $OUT_FILE"
