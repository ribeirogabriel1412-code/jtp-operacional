# Descobre qual tabela/campo da Oracle (GLOBUS868) representa BAIXA de material
# do estoque (saida confirmada), pra usar como "norte" na checagem de cobertura
# do inventario (todo material baixado precisa aparecer numa contagem depois).
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
Write-Host "=== 1) Tabelas do schema GLOBUS868 com nome parecido com movimentacao/saida/baixa/kardex/estoque ===" -ForegroundColor Yellow
$tabs = Roda-Query @"
SELECT TABLE_NAME FROM ALL_TABLES
WHERE OWNER='GLOBUS868'
  AND (TABLE_NAME LIKE '%MOVIMENT%' OR TABLE_NAME LIKE '%SAIDA%' OR TABLE_NAME LIKE '%BAIXA%'
       OR TABLE_NAME LIKE '%KARDEX%' OR TABLE_NAME LIKE '%ESTOQUE%' OR TABLE_NAME LIKE 'EST\_%' ESCAPE '\')
ORDER BY TABLE_NAME
"@
foreach ($t in $tabs) { Write-Host "  $($t.TABLE_NAME)" }

Write-Host ""
Write-Host "=== 2) Valores distintos de STATUSITREQ em EST_ITENSREQUISICAO (pode ser aqui que mora 'baixado') ===" -ForegroundColor Yellow
$status = Roda-Query "SELECT STATUSITREQ, COUNT(*) AS QTD FROM GLOBUS868.EST_ITENSREQUISICAO GROUP BY STATUSITREQ ORDER BY QTD DESC"
foreach ($s in $status) { Write-Host "  STATUSITREQ='$($s.STATUSITREQ)' -- $($s.QTD) linhas" }

$conn.Close()
Write-Host ""
Write-Host "Concluido em $(Get-Date)." -ForegroundColor Green
