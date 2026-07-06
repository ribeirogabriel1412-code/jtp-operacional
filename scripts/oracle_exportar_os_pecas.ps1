# Exporta OS + pecas requisitadas direto da Oracle (PRAXIO), pra cruzar com o
# que o app tem em ocorrencias_22 (campo praxio_os_id ja existe e liga as duas
# pontas). Mesma cadeia de join ja validada no motor_custo.ps1:
#   PI_MAN.CODINTOS = EST_REQUISICAO.CODINTOS  (NAO usar NUMERO_OS pra join interno,
#   ele recicla -- mas o NUMERO_OS final exportado aqui serve pra bater com
#   ocorrencias_22.praxio_os_id, que e por natureza um numero recente/unico o
#   suficiente dentro da janela que a gente usa)
#
# RODAR NO SERVIDOR. Senha vem de $env:JTP_ORACLE_PWD.
# Gera CSV em C:\sync_praxio\relatorios\os_pecas_oracle.csv
#
# USO:
#   .\oracle_exportar_os_pecas.ps1 -DataInicio "2026-06-01" -DataFim "2026-07-06"

param(
    [string]$DataInicio,
    [string]$DataFim
)

$DSN = "GLOBUSSERVER"
$UID = if ($env:JTP_ORACLE_UID) { $env:JTP_ORACLE_UID } else { "CONSULTA868" }
$PWD_ORACLE = if ($env:JTP_ORACLE_PWD) { $env:JTP_ORACLE_PWD } else { "COLE_AQUI" }
$OUT_CSV = "C:\sync_praxio\relatorios\os_pecas_oracle.csv"

if (-not $DataFim) { $DataFim = (Get-Date).ToString("yyyy-MM-dd") }
if (-not $DataInicio) { $DataInicio = (Get-Date).AddDays(-60).ToString("yyyy-MM-dd") }

Add-Type -AssemblyName System.Data
$conn = New-Object System.Data.Odbc.OdbcConnection
$conn.ConnectionString = "DSN=$DSN;UID=$UID;PWD=$PWD_ORACLE"
$conn.Open()
Write-Host "Conectado -- $(Get-Date)" -ForegroundColor Green
Write-Host "Periodo: $DataInicio ate $DataFim" -ForegroundColor Yellow

function Roda-Query($sql, $timeout = 180) {
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

Write-Host "Consultando OS + pecas na Oracle..." -ForegroundColor Cyan
$sql = @"
SELECT p.NUMERO_OS, p.CODINTOS, p.PREFIXO_VEIC, p.FILIAL, p.DATA_OS, p.CONDICAO_OS, p.TIPOOS,
       r.NUMERORQ, c.DESCRICAOMAT, it.QTDEITREQ, it.VALORTOTALITREQ, it.STATUSITREQ
FROM (
    SELECT CODINTOS, MIN(NUMERO_OS) AS NUMERO_OS, MIN(PREFIXO_VEIC) AS PREFIXO_VEIC,
           MIN(FILIAL) AS FILIAL, MIN(DATA_OS) AS DATA_OS,
           MAX(CONDICAO_OS) AS CONDICAO_OS, MIN(TIPOOS) AS TIPOOS
    FROM GLOBUS868.PI_MAN
    WHERE DATA_OS >= TO_DATE('$DataInicio','YYYY-MM-DD')
      AND DATA_OS <= TO_DATE('$DataFim','YYYY-MM-DD') + 1
    GROUP BY CODINTOS
) p
JOIN GLOBUS868.EST_REQUISICAO r ON r.CODINTOS = p.CODINTOS
JOIN GLOBUS868.EST_ITENSREQUISICAO it ON it.NUMERORQ = r.NUMERORQ
JOIN GLOBUS868.EST_CADMATERIAL c ON c.CODIGOMATINT = it.CODIGOMATINT
ORDER BY p.NUMERO_OS
"@
$r = Roda-Query $sql 180
Write-Host "$($r.Count) itens de requisicao encontrados." -ForegroundColor Green

$r | Export-Csv -Path $OUT_CSV -NoTypeInformation -Encoding UTF8

$conn.Close()
Write-Host ""
Write-Host "Exportado para: $OUT_CSV" -ForegroundColor Green
Write-Host "Concluido em $(Get-Date)."
