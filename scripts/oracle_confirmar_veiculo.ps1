# Confirma se CODIGOVEIC realmente veio nulo no JOIN via EST_REQUISICAO,
# ou se foi so sumico de exibicao do Format-Table.
# RODAR NO SERVIDOR. Senha vem de $env:JTP_ORACLE_PWD.

$DSN = "GLOBUSSERVER"
$UID = if ($env:JTP_ORACLE_UID) { $env:JTP_ORACLE_UID } else { "CONSULTA868" }
$PWD_ORACLE = if ($env:JTP_ORACLE_PWD) { $env:JTP_ORACLE_PWD } else { "COLE_AQUI" }
$OUT_FILE = "C:\sync_praxio\relatorios\confirmar_veiculo.txt"

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

$sql = @"
SELECT m.DATAMOVTO, m.NUMERORQ, i.CODIGOMATINT, c.DESCRICAOMAT, r.CODIGOVEIC, r.NUMERORQ AS NUMERORQ_REQ
FROM GLOBUS868.EST_MOVTO m
JOIN GLOBUS868.EST_ITENSOUTENT i ON i.NROUTRENT = m.NROUTRENT
JOIN GLOBUS868.EST_CADMATERIAL c ON c.CODIGOMATINT = i.CODIGOMATINT
LEFT JOIN GLOBUS868.EST_REQUISICAO r ON r.NUMERORQ = m.NUMERORQ
WHERE m.DATAMOVTO >= TO_DATE('2026-06-25','YYYY-MM-DD')
  AND m.DATAMOVTO <  TO_DATE('2026-06-29','YYYY-MM-DD')
  AND ROWNUM <= 20
"@
$r = Roda-Query $sql 60
Log "Linhas: $($r.Count)"
foreach ($row in $r) {
    Log "DATA=$($row.DATAMOVTO) NUMERORQ(movto)=$($row.NUMERORQ) MATERIAL=$($row.DESCRICAOMAT) | CODIGOVEIC=$($row.CODIGOVEIC) | NUMERORQ(req)=$($row.NUMERORQ_REQ)"
}

$conn.Close()
Log ""
Log "Concluido em $(Get-Date). Arquivo salvo em: $OUT_FILE"
