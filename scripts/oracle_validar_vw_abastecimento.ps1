# Valida a VW_LANCAMENTOABASTECIMENTO: amostra recente de verdade + checa se
# KM_POR_L vem preenchido com valores reais (nao zerado feito o MEDIACONSUMO).
# RODAR NO SERVIDOR. Senha vem de $env:JTP_ORACLE_PWD.

$DSN = "GLOBUSSERVER"
$UID = if ($env:JTP_ORACLE_UID) { $env:JTP_ORACLE_UID } else { "CONSULTA868" }
$PWD_ORACLE = if ($env:JTP_ORACLE_PWD) { $env:JTP_ORACLE_PWD } else { "COLE_AQUI" }
$OUT_FILE = "C:\sync_praxio\relatorios\validar_vw_abastecimento.txt"

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

$T = "GLOBUS868.VW_LANCAMENTOABASTECIMENTO"

Log ""
Log "=== Amostra recente de verdade (top 15, ordenado por DATA_ABASTECIMENTO DESC) ==="
try {
    $r = Roda-Query @"
SELECT * FROM (
  SELECT PREFIXO, PLACA, DATA_ABASTECIMENTO, HORA_ABASTECIMENTO, QUANTIDADE_COMBUSTIVEL,
         HODOMETRO_INICIAL, HODOMETRO_FINAL, KM_PERCORRIDO, KM_POR_L, NOME_MOTORISTA, GARAGEM
  FROM $T
  ORDER BY DATA_ABASTECIMENTO DESC
) WHERE ROWNUM <= 15
"@
    Log ($r | Format-Table -AutoSize | Out-String -Width 300)
} catch {
    Log "Falhou: $($_.Exception.Message)"
}

Log ""
Log "=== Data mais recente na view e qtd ultimos 60 dias ==="
try {
    $r2 = Roda-Query "SELECT MAX(DATA_ABASTECIMENTO) AS DATA_MAX, COUNT(*) AS TOTAL_60D FROM $T WHERE DATA_ABASTECIMENTO >= SYSDATE - 60"
    Log "Data mais recente: $($r2[0].DATA_MAX) | Registros ultimos 60 dias: $($r2[0].TOTAL_60D)"
} catch { Log "Falhou: $($_.Exception.Message)" }

Log ""
Log "=== KM_POR_L: nulo vs > 0 vs = 0 (ultimos 60 dias) ==="
try {
    $r3 = Roda-Query "SELECT COUNT(*) AS TOTAL, SUM(CASE WHEN KM_POR_L IS NULL THEN 1 ELSE 0 END) AS NULOS, SUM(CASE WHEN KM_POR_L = 0 THEN 1 ELSE 0 END) AS ZERADOS, SUM(CASE WHEN KM_POR_L > 0 THEN 1 ELSE 0 END) AS COM_VALOR FROM $T WHERE DATA_ABASTECIMENTO >= SYSDATE - 60"
    Log "Total: $($r3[0].TOTAL) | Nulos: $($r3[0].NULOS) | Zerados: $($r3[0].ZERADOS) | Com valor > 0: $($r3[0].COM_VALOR)"
} catch { Log "Falhou: $($_.Exception.Message)" }

Log ""
Log "=== Amostra so com KM_POR_L > 0 (ultimos 60 dias, top 15) ==="
try {
    $r4 = Roda-Query @"
SELECT * FROM (
  SELECT PREFIXO, PLACA, DATA_ABASTECIMENTO, QUANTIDADE_COMBUSTIVEL, KM_PERCORRIDO, KM_POR_L, GARAGEM
  FROM $T
  WHERE KM_POR_L > 0 AND DATA_ABASTECIMENTO >= SYSDATE - 60
  ORDER BY DATA_ABASTECIMENTO DESC
) WHERE ROWNUM <= 15
"@
    Log ($r4 | Format-Table -AutoSize | Out-String -Width 300)
} catch { Log "Falhou: $($_.Exception.Message)" }

$conn.Close()
Log ""
Log "Concluido em $(Get-Date). Arquivo salvo em: $OUT_FILE"
