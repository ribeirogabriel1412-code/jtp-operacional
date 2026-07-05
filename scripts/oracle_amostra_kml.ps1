# Amostra focada nos campos de Km/L da tabela ABA_ITEMABASTCARRO
# RODAR NO SERVIDOR. Senha vem de $env:JTP_ORACLE_PWD.

$DSN = "GLOBUSSERVER"
$UID = if ($env:JTP_ORACLE_UID) { $env:JTP_ORACLE_UID } else { "CONSULTA868" }
$PWD_ORACLE = if ($env:JTP_ORACLE_PWD) { $env:JTP_ORACLE_PWD } else { "COLE_AQUI" }
$OUT_FILE = "C:\sync_praxio\relatorios\amostra_kml.txt"

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

Log ""
Log "=== Amostra com MEDIACONSUMO preenchido (top 20 mais recentes) ==="
try {
    # Subquery e' necessario: ROWNUM filtra ANTES do ORDER BY no Oracle, entao
    # "WHERE ROWNUM<=20 ORDER BY X DESC" pega 20 linhas arbitrarias e so ordena
    # essas -- nao as 20 mais recentes de verdade. Tambem filtra > 0, nao so IS NOT NULL
    # (muitas linhas tem MEDIACONSUMO = 0, nao nulo, mas sem valor util).
    $r = Roda-Query @"
SELECT * FROM (
  SELECT CODIGOVEIC, DATAABASTCARRO, TIPOABASTCARRO, KMTOTALPERCORRIDO,
         VELOCIDADEMEDIA, MEDIACONSUMO, QTDEITEMABASTCARRO, TANQUECHEIO
  FROM GLOBUS868.ABA_ITEMABASTCARRO
  WHERE MEDIACONSUMO > 0
  ORDER BY DATAABASTCARRO DESC
) WHERE ROWNUM <= 20
"@
    Log ($r | Format-Table -AutoSize | Out-String -Width 300)
    Log "Linhas retornadas: $($r.Count)"
} catch {
    Log "Falhou (talvez a coluna GARAGEM nao exista nessa tabela): $($_.Exception.Message)"
}

Log ""
Log "=== Quantas linhas tem MEDIACONSUMO preenchido vs total (ultimos 60 dias) ==="
try {
    $r2 = Roda-Query "SELECT COUNT(*) AS TOTAL, SUM(CASE WHEN MEDIACONSUMO IS NOT NULL THEN 1 ELSE 0 END) AS NAO_NULO, SUM(CASE WHEN MEDIACONSUMO > 0 THEN 1 ELSE 0 END) AS MAIOR_QUE_ZERO, MAX(DATAABASTCARRO) AS DATA_MAIS_RECENTE FROM GLOBUS868.ABA_ITEMABASTCARRO WHERE DATAABASTCARRO >= SYSDATE - 60"
    Log "Total ultimos 60 dias: $($r2[0].TOTAL) | MEDIACONSUMO nao-nulo: $($r2[0].NAO_NULO) | MEDIACONSUMO > 0: $($r2[0].MAIOR_QUE_ZERO) | Data mais recente na tabela: $($r2[0].DATA_MAIS_RECENTE)"
} catch {
    Log "Falhou: $($_.Exception.Message)"
}

$conn.Close()
Log ""
Log "Concluido em $(Get-Date). Arquivo salvo em: $OUT_FILE"
