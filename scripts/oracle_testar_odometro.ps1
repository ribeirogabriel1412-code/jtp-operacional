# Compara KM_PERCORRIDO (calculado pela view) vs HODOMETRO_FINAL - HODOMETRO_INICIAL
# (calculado por nos, na mesma linha) -- ideia do Daniel pra contornar o bug da
# view em dias com 2+ abastecimentos (ver achado de 2026-07-06).
# RODAR NO SERVIDOR. Senha vem de $env:JTP_ORACLE_PWD.

$DSN = "GLOBUSSERVER"
$UID = if ($env:JTP_ORACLE_UID) { $env:JTP_ORACLE_UID } else { "CONSULTA868" }
$PWD_ORACLE = if ($env:JTP_ORACLE_PWD) { $env:JTP_ORACLE_PWD } else { "COLE_AQUI" }
$OUT_FILE = "C:\sync_praxio\relatorios\teste_odometro.txt"

Add-Type -AssemblyName System.Data
$conn = New-Object System.Data.Odbc.OdbcConnection
$conn.ConnectionString = "DSN=$DSN;UID=$UID;PWD=$PWD_ORACLE"
$conn.Open()

New-Item -ItemType Directory -Path (Split-Path $OUT_FILE) -Force | Out-Null
if (Test-Path $OUT_FILE) { Remove-Item $OUT_FILE -Force }
function Log($t) { Write-Host $t; Add-Content -Path $OUT_FILE -Value $t -Encoding UTF8 }

Log "Conectado -- $(Get-Date)"

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

foreach ($veic in @("02188", "02203")) {
    Log ""
    Log "=== Veiculo terminado em $veic ==="
    $sql = @"
SELECT DATA_ABASTECIMENTO, HORA_ABASTECIMENTO, HODOMETRO_INICIAL, HODOMETRO_FINAL,
       KM_PERCORRIDO, KM_ACUMULADO, KM_POR_L, QUANTIDADE_COMBUSTIVEL
FROM GLOBUS868.VW_LANCAMENTOABASTECIMENTO
WHERE PREFIXO LIKE '%$veic'
  AND DATA_ABASTECIMENTO >= TO_DATE('2026-06-28','YYYY-MM-DD')
  AND DATA_ABASTECIMENTO <  TO_DATE('2026-07-05','YYYY-MM-DD')
ORDER BY HORA_ABASTECIMENTO
"@
    try {
        $r = Roda-Query $sql 60
        Log ("  {0,-20} {1,-10} {2,-10} {3,-8} {4,-8} {5,-10} {6,-8} {7}" -f "HORA_ABAST","HOD_INI","HOD_FIM","KM_MANUAL","KM_VIEW","KM_ACUM","KM_POR_L","QTD_COMB")
        foreach ($linha in $r) {
            $kmManual = if ($linha.HODOMETRO_FINAL -ne $null -and $linha.HODOMETRO_INICIAL -ne $null) { $linha.HODOMETRO_FINAL - $linha.HODOMETRO_INICIAL } else { "?" }
            Log ("  {0,-20} {1,-10} {2,-10} {3,-8} {4,-8} {5,-10} {6,-8} {7}" -f "$($linha.HORA_ABASTECIMENTO)", "$($linha.HODOMETRO_INICIAL)", "$($linha.HODOMETRO_FINAL)", "$kmManual", "$($linha.KM_PERCORRIDO)", "$($linha.KM_ACUMULADO)", "$($linha.KM_POR_L)", "$($linha.QUANTIDADE_COMBUSTIVEL)")
        }
    } catch {
        Log "  Erro: $($_.Exception.Message)"
    }
}

$conn.Close()
Log ""
Log "Concluido em $(Get-Date). Salvo em $OUT_FILE"
