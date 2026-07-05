# Diagnostico: por que 02.188 e 02.203 tem poucos abastecimentos registrados
# entre 28/06 e 04/07/2026, quando o padrao historico e quase diario?
# Objetivo: ver TODAS as linhas cruas da view nesse periodo, SEM nenhum filtro
# de KM_POR_L, pra saber se o dado existe na Oracle e esta sendo descartado
# pelo nosso filtro, ou se realmente nao existe na origem.
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

foreach ($veic in @("02188", "02203")) {
    Write-Host ""
    Write-Host "=== Veiculo terminado em $veic -- TODAS as linhas cruas 28/06 a 04/07 (sem filtro nenhum) ===" -ForegroundColor Yellow
    $sql = @"
SELECT PREFIXO, PLACA, DATA_ABASTECIMENTO, KM_PERCORRIDO, KM_POR_L, QUANTIDADE_COMBUSTIVEL
FROM GLOBUS868.VW_LANCAMENTOABASTECIMENTO
WHERE PREFIXO LIKE '%$veic'
  AND DATA_ABASTECIMENTO >= TO_DATE('2026-06-28','YYYY-MM-DD')
  AND DATA_ABASTECIMENTO <  TO_DATE('2026-07-05','YYYY-MM-DD')
ORDER BY DATA_ABASTECIMENTO
"@
    try {
        $r = Roda-Query $sql 60
        Write-Host "  $($r.Count) linhas encontradas (SEM filtro de KM_POR_L)." -ForegroundColor Cyan
        foreach ($linha in $r) {
            Write-Host "  $($linha.DATA_ABASTECIMENTO)  PREFIXO=$($linha.PREFIXO)  PLACA=$($linha.PLACA)  KM_PERCORRIDO=$($linha.KM_PERCORRIDO)  KM_POR_L=$($linha.KM_POR_L)  QTD_COMBUSTIVEL=$($linha.QUANTIDADE_COMBUSTIVEL)"
        }
    } catch {
        Write-Warning "  Erro consultando sem filtro: $($_.Exception.Message)"
        Write-Host "  Tentando dia a dia pra achar a linha exata que quebra..." -ForegroundColor DarkYellow
        $dia = [datetime]::ParseExact("2026-06-28","yyyy-MM-dd",$null)
        $fim = [datetime]::ParseExact("2026-07-04","yyyy-MM-dd",$null)
        while ($dia -le $fim) {
            $diaStr = $dia.ToString("yyyy-MM-dd")
            try {
                $rd = Roda-Query "SELECT PREFIXO, PLACA, DATA_ABASTECIMENTO, KM_PERCORRIDO, KM_POR_L, QUANTIDADE_COMBUSTIVEL FROM GLOBUS868.VW_LANCAMENTOABASTECIMENTO WHERE PREFIXO LIKE '%$veic' AND DATA_ABASTECIMENTO >= TO_DATE('$diaStr','YYYY-MM-DD') AND DATA_ABASTECIMENTO < TO_DATE('$diaStr','YYYY-MM-DD')+1" 60
                Write-Host "    $diaStr -- OK, $($rd.Count) linha(s)"
                foreach ($linha in $rd) {
                    Write-Host "      KM_PERCORRIDO=$($linha.KM_PERCORRIDO)  KM_POR_L=$($linha.KM_POR_L)  QTD_COMBUSTIVEL=$($linha.QUANTIDADE_COMBUSTIVEL)  PLACA=$($linha.PLACA)"
                }
            } catch {
                Write-Warning "    $diaStr -- FALHOU: $($_.Exception.Message)"
            }
            $dia = $dia.AddDays(1)
        }
    }
}

$conn.Close()
Write-Host ""
Write-Host "Concluido em $(Get-Date)." -ForegroundColor Green
