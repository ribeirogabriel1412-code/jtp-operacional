# Exporta hodometro/km de TODA a frota num periodo, pra comparar em massa
# com a planilha CTAPLUS e ver se a divergencia de hodometro (achada nos
# testes com 02.188/02.203 em 2026-07-06) e um problema isolado ou generalizado.
# RODAR NO SERVIDOR. Senha vem de $env:JTP_ORACLE_PWD.
# Gera CSV em C:\sync_praxio\relatorios\frota_hodometro_oracle.csv

$DSN = "GLOBUSSERVER"
$UID = if ($env:JTP_ORACLE_UID) { $env:JTP_ORACLE_UID } else { "CONSULTA868" }
$PWD_ORACLE = if ($env:JTP_ORACLE_PWD) { $env:JTP_ORACLE_PWD } else { "COLE_AQUI" }
$OUT_CSV = "C:\sync_praxio\relatorios\frota_hodometro_oracle.csv"

$DATA_INICIO = "2026-06-28"
$DATA_FIM    = "2026-07-06"

Add-Type -AssemblyName System.Data
$conn = New-Object System.Data.Odbc.OdbcConnection
$conn.ConnectionString = "DSN=$DSN;UID=$UID;PWD=$PWD_ORACLE"
$conn.Open()
Write-Host "Conectado -- $(Get-Date)" -ForegroundColor Green

function Roda-Query($sql, $timeout = 120) {
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

Write-Host "Consultando toda a frota ($DATA_INICIO a $DATA_FIM)..." -ForegroundColor Cyan
$sql = @"
SELECT PREFIXO, PLACA, DATA_ABASTECIMENTO, HORA_ABASTECIMENTO,
       HODOMETRO_INICIAL, HODOMETRO_FINAL, KM_PERCORRIDO, KM_POR_L,
       QUANTIDADE_COMBUSTIVEL
FROM GLOBUS868.VW_LANCAMENTOABASTECIMENTO
WHERE DATA_ABASTECIMENTO >= TO_DATE('$DATA_INICIO','YYYY-MM-DD')
  AND DATA_ABASTECIMENTO <  TO_DATE('$DATA_FIM','YYYY-MM-DD')
  AND PLACA IS NOT NULL
ORDER BY PREFIXO, DATA_ABASTECIMENTO
"@
$r = Roda-Query $sql 180
Write-Host "$($r.Count) linhas encontradas." -ForegroundColor Green

$r | Select-Object PREFIXO, PLACA, DATA_ABASTECIMENTO, HORA_ABASTECIMENTO, HODOMETRO_INICIAL, HODOMETRO_FINAL, KM_PERCORRIDO, KM_POR_L, QUANTIDADE_COMBUSTIVEL |
    Export-Csv -Path $OUT_CSV -NoTypeInformation -Encoding UTF8

$conn.Close()
Write-Host ""
Write-Host "Exportado para: $OUT_CSV" -ForegroundColor Green
Write-Host "Concluido em $(Get-Date)."
