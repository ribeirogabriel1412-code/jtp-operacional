# Investiga por que EST_REQUISICAO repete linhas identicas pra mesma OS+requisicao,
# multiplicando o custo no JOIN com EST_ITENSREQUISICAO.
# RODAR NO SERVIDOR. Senha vem de $env:JTP_ORACLE_PWD.

$DSN = "GLOBUSSERVER"
$UID = if ($env:JTP_ORACLE_UID) { $env:JTP_ORACLE_UID } else { "CONSULTA868" }
$PWD_ORACLE = if ($env:JTP_ORACLE_PWD) { $env:JTP_ORACLE_PWD } else { "COLE_AQUI" }
$OUT_FILE = "C:\sync_praxio\relatorios\diagnostico_duplicacao_custo.txt"

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
Log "=== EST_REQUISICAO cru pra CODINTOS=88536 (a OS 16142 que ja testamos) ==="
$r1 = Roda-Query "SELECT * FROM GLOBUS868.EST_REQUISICAO WHERE CODINTOS = 88536"
Log "Linhas: $($r1.Count)"
Log ($r1 | Format-Table -AutoSize | Out-String -Width 300)

Log ""
Log "=== EST_ITENSREQUISICAO cru pra NUMERORQ=1030009107 ==="
$r2 = Roda-Query "SELECT * FROM GLOBUS868.EST_ITENSREQUISICAO WHERE NUMERORQ = 1030009107"
Log "Linhas: $($r2.Count)"
Log ($r2 | Format-Table -AutoSize | Out-String -Width 300)

$conn.Close()
Log ""
Log "Concluido em $(Get-Date). Arquivo salvo em: $OUT_FILE"
