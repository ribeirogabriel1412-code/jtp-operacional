# Busca a tabela de catalogo de materiais (CODIGOMATINT -> descricao),
# pra completar o JOIN de custo (EST_MOVTO + EST_ITENSOUTENT/EST_SERVOUTENT).
# RODAR NO SERVIDOR. Senha vem de $env:JTP_ORACLE_PWD.

$DSN = "GLOBUSSERVER"
$UID = if ($env:JTP_ORACLE_UID) { $env:JTP_ORACLE_UID } else { "CONSULTA868" }
$PWD_ORACLE = if ($env:JTP_ORACLE_PWD) { $env:JTP_ORACLE_PWD } else { "COLE_AQUI" }
$OUT_FILE = "C:\sync_praxio\relatorios\buscar_catalogo_material.txt"

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
Log "=== Tabelas com nome sugerindo catalogo de material/produto ==="
$r0 = Roda-Query "SELECT DISTINCT OWNER, TABLE_NAME FROM ALL_TABLES WHERE TABLE_NAME LIKE '%MATERIAL%' OR TABLE_NAME LIKE '%CADMAT%' OR TABLE_NAME LIKE '%PRODUTO%' OR TABLE_NAME LIKE '%CADITEM%'"
$r0 | Format-Table -AutoSize | Out-String -Width 200 | ForEach-Object { Log $_ }

Log ""
Log "=== Colunas chamadas CODIGOMATINT em qualquer tabela (achar a tabela-mae) ==="
$r1 = Roda-Query "SELECT OWNER, TABLE_NAME, COLUMN_NAME FROM ALL_TAB_COLUMNS WHERE COLUMN_NAME = 'CODIGOMATINT' ORDER BY TABLE_NAME"
$r1 | Format-Table -AutoSize | Out-String -Width 200 | ForEach-Object { Log $_ }

Log ""
Log "=== Colunas com DESCRICAO + algum CODIGO de material na mesma tabela (candidatas a catalogo) ==="
$r2 = Roda-Query "SELECT OWNER, TABLE_NAME, COLUMN_NAME FROM ALL_TAB_COLUMNS WHERE COLUMN_NAME LIKE '%DESCRMAT%' OR COLUMN_NAME LIKE '%DESCMATERIAL%' OR COLUMN_NAME LIKE '%DESCRICAOMAT%' ORDER BY TABLE_NAME"
$r2 | Format-Table -AutoSize | Out-String -Width 200 | ForEach-Object { Log $_ }

$conn.Close()
Log ""
Log "Concluido em $(Get-Date). Arquivo salvo em: $OUT_FILE"
