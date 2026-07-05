# Testa se CODINTOS (nao NUMERO_OS) e' o identificador unico real de cada OS.
# RODAR NO SERVIDOR. Senha vem de $env:JTP_ORACLE_PWD.

$DSN = "GLOBUSSERVER"
$UID = if ($env:JTP_ORACLE_UID) { $env:JTP_ORACLE_UID } else { "CONSULTA868" }
$PWD_ORACLE = if ($env:JTP_ORACLE_PWD) { $env:JTP_ORACLE_PWD } else { "COLE_AQUI" }
$OUT_FILE = "C:\sync_praxio\relatorios\testar_codintos.txt"

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
Log "=== Registros da 'OS 16127' de novo, agora trazendo CODINTOS ==="
$r1 = Roda-Query "SELECT NUMERO_OS, CODINTOS, PREFIXO_VEIC, DATA_OS, CONDICAO_OS, SEQ FROM GLOBUS868.PI_MAN WHERE NUMERO_OS = 16127"
$r1 | Format-Table -AutoSize | Out-String -Width 250 | ForEach-Object { Log $_ }

Log ""
Log "=== Contagem por CODINTOS, mesmo filtro de antes (PVH, junho/2026) ==="
$r2 = Roda-Query @"
SELECT COUNT(DISTINCT CODINTOS) AS QTD_CODINTOS, COUNT(DISTINCT NUMERO_OS) AS QTD_NUMERO_OS, COUNT(*) AS TOTAL_LINHAS
FROM GLOBUS868.PI_MAN
WHERE FILIAL LIKE '%PORTO VELHO%'
  AND DATA_OS >= TO_DATE('2026-06-01','YYYY-MM-DD')
  AND DATA_OS <  TO_DATE('2026-07-01','YYYY-MM-DD')
"@
Log "Qtd CODINTOS distintos: $($r2[0].QTD_CODINTOS) | Qtd NUMERO_OS distintos: $($r2[0].QTD_NUMERO_OS) | Total linhas: $($r2[0].TOTAL_LINHAS)"

Log ""
Log "=== Distribuicao CONDICAO_OS agrupando por CODINTOS (1 linha por OS real) ==="
$r3 = Roda-Query @"
SELECT CODINTOS, MIN(NUMERO_OS) AS NUMERO_OS, MIN(PREFIXO_VEIC) AS PREFIXO_VEIC, MIN(DATA_OS) AS DATA_OS, MIN(CONDICAO_OS) AS CONDICAO_OS
FROM GLOBUS868.PI_MAN
WHERE FILIAL LIKE '%PORTO VELHO%'
  AND DATA_OS >= TO_DATE('2026-06-01','YYYY-MM-DD')
  AND DATA_OS <  TO_DATE('2026-07-01','YYYY-MM-DD')
GROUP BY CODINTOS
"@
Log "Total de OS unicas (por CODINTOS): $($r3.Count)"
$r3 | Group-Object CONDICAO_OS | ForEach-Object { Log "  $($_.Name): $($_.Count)" }

$conn.Close()
Log ""
Log "Concluido em $(Get-Date). Arquivo salvo em: $OUT_FILE"
