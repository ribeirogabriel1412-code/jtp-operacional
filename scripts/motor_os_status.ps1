# Motor de OS por Status -- JTP Transportes
# Consolida preventiva + corretiva do PI_MAN (deduplicado por CODINTOS) num
# unico motor: quantas OS estao abertas, fechadas ou canceladas, por veiculo
# e por tipo, no periodo.
#
# Validado em 2026-07-05 contra Excel real do painel "Cumprimento de Revisao":
#   Preventiva Pesada: 29 (Oracle) vs 28 (Excel) -- diferenca explicada (carro
#     puxado fora da programacao por estar vencendo no km)
#   Preventiva Leve: 174 (Oracle) vs 142 (Excel) -- diferenca explicada (toda
#     pesada already inclui a leve, entao leve "real" > leve programada isolada)
#   Corretiva: 246 OS unicas (limpo, sem duplicacao no PI_MAN)
#
# IMPORTANTE: PI_MAN tem multiplas linhas por OS (audit trail -- cada alteracao
# vira linha nova). SEMPRE deduplicar por CODINTOS antes de contar/agregar,
# nunca usar NUMERO_OS sozinho (recicla ao longo do tempo).
#
# NAO grava nada no Supabase -- etapa de validacao manual dos calculos.
# RODAR NO SERVIDOR (unico lugar com IP liberado no ODBC GLOBUSSERVER).
# Senha vem de $env:JTP_ORACLE_PWD (setar antes de rodar, nunca colar aqui).
#
# USO:
#   .\motor_os_status.ps1 -DataInicio "2026-06-01" -DataFim "2026-06-30" -Garagem PVH

param(
    [string]$DataInicio,
    [string]$DataFim,
    [string]$Garagem  # "PVH" (Porto Velho) ou "BRA" (Braganca) -- vazio = todas
)

$DSN = "GLOBUSSERVER"
$UID = if ($env:JTP_ORACLE_UID) { $env:JTP_ORACLE_UID } else { "CONSULTA868" }
$PWD_ORACLE = if ($env:JTP_ORACLE_PWD) { $env:JTP_ORACLE_PWD } else { "COLE_AQUI" }
$OUT_DIR = "C:\sync_praxio\relatorios"
New-Item -ItemType Directory -Path $OUT_DIR -Force | Out-Null

if (-not $DataFim) { $DataFim = (Get-Date).ToString("yyyy-MM-dd") }
if (-not $DataInicio) {
    $hoje = Get-Date
    $DataInicio = (Get-Date -Year $hoje.Year -Month $hoje.Month -Day 1).AddMonths(-1).ToString("yyyy-MM-dd")
}

$FILIAL_MAP = @{ "PVH" = "PORTO VELHO"; "BRA" = "BRAGAN" }
$filtroFilial = ""
if ($Garagem) {
    if (-not $FILIAL_MAP.ContainsKey($Garagem)) {
        Write-Warning "Garagem '$Garagem' desconhecida. Use PVH ou BRA."
    } else {
        $filtroFilial = "AND FILIAL LIKE '%$($FILIAL_MAP[$Garagem])%'"
    }
}

Write-Host "Motor de OS por Status" -ForegroundColor Yellow
Write-Host "Periodo: $DataInicio ate $DataFim | Garagem: $(if ($Garagem) { $Garagem } else { 'Todas' })" -ForegroundColor Yellow

function Formata-Prefixo($raw) {
    $s = "$raw".Trim()
    if ($s.Length -ge 5 -and $s -match '^\d+$') {
        $last5 = $s.Substring($s.Length - 5)
        return $last5.Substring(0,2) + "." + $last5.Substring(2)
    }
    return $s
}

Add-Type -AssemblyName System.Data
$conn = New-Object System.Data.Odbc.OdbcConnection
$conn.ConnectionString = "DSN=$DSN;UID=$UID;PWD=$PWD_ORACLE"
$conn.Open()

function Roda-Query($sql, $timeout = 180) {
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

Write-Host "Consultando Oracle..." -ForegroundColor Cyan
$sql = @"
SELECT CODINTOS, MIN(NUMERO_OS) AS NUMERO_OS, MIN(PREFIXO_VEIC) AS PREFIXO_VEIC,
       MIN(DATA_OS) AS DATA_OS, MAX(CONDICAO_OS) AS CONDICAO_OS,
       MIN(TIPOOS) AS TIPOOS, MIN(REVISAO) AS REVISAO,
       MIN(GRUPO_DEFEITO) AS GRUPO_DEFEITO
FROM GLOBUS868.PI_MAN
WHERE DATA_OS >= TO_DATE('$DataInicio','YYYY-MM-DD')
  AND DATA_OS <= TO_DATE('$DataFim','YYYY-MM-DD') + 1
  $filtroFilial
GROUP BY CODINTOS
"@
$os = Roda-Query $sql 180
Write-Host "$($os.Count) OS unicas encontradas." -ForegroundColor Green

if ($os.Count -eq 0) {
    Write-Host "Nenhum dado encontrado no periodo." -ForegroundColor Red
    $conn.Close()
    return
}

# -- Resumo geral por status -------------------------------------------------
Write-Host ""
Write-Host "=== TOTAL DO PERIODO ===" -ForegroundColor Cyan
Write-Host "OS unicas: $($os.Count)" -ForegroundColor Cyan
Write-Host "--- Por status ---" -ForegroundColor Yellow
$os | Group-Object CONDICAO_OS | Sort-Object Count -Descending | ForEach-Object {
    Write-Host "  $($_.Name): $($_.Count)"
}
Write-Host "--- Por tipo ---" -ForegroundColor Yellow
$os | Group-Object TIPOOS | Sort-Object Count -Descending | ForEach-Object {
    Write-Host "  $($_.Name): $($_.Count)"
}

# -- Agregado por veiculo -----------------------------------------------------
$porVeiculo = $os | Group-Object PREFIXO_VEIC | ForEach-Object {
    $abertas    = @($_.Group | Where-Object { $_.CONDICAO_OS -eq 'ABERTA' }).Count
    $fechadas   = @($_.Group | Where-Object { $_.CONDICAO_OS -eq 'FECHADA COMPLETA' }).Count
    $canceladas = @($_.Group | Where-Object { $_.CONDICAO_OS -eq 'CA' }).Count
    $preventivas = @($_.Group | Where-Object { $_.TIPOOS -eq 'PREVENTIVA' }).Count
    $corretivas  = @($_.Group | Where-Object { $_.TIPOOS -eq 'CORRETIVA' }).Count
    [PSCustomObject]@{
        prefixo      = Formata-Prefixo $_.Name
        qtd_os       = $_.Count
        abertas      = $abertas
        fechadas     = $fechadas
        canceladas   = $canceladas
        preventivas  = $preventivas
        corretivas   = $corretivas
    }
} | Sort-Object qtd_os -Descending

Write-Host ""
Write-Host "--- Top 15 veiculos por quantidade de OS ---" -ForegroundColor Yellow
$porVeiculo | Select-Object -First 15 | Format-Table -AutoSize

# -- Top defeitos (so corretivas) --------------------------------------------
Write-Host "--- Top 10 grupos de defeito (corretivas) ---" -ForegroundColor Yellow
$os | Where-Object { $_.TIPOOS -eq 'CORRETIVA' } | Group-Object GRUPO_DEFEITO | Sort-Object Count -Descending | Select-Object -First 10 | ForEach-Object {
    Write-Host "  $($_.Name): $($_.Count)"
}

$sufixo = "$($DataInicio)_a_$($DataFim)_$(if ($Garagem) { $Garagem } else { 'todas' })"
$os         | Export-Csv -Path "$OUT_DIR\os_status_detalhe_$sufixo.csv"   -NoTypeInformation -Encoding UTF8
$porVeiculo | Export-Csv -Path "$OUT_DIR\os_status_por_veiculo_$sufixo.csv" -NoTypeInformation -Encoding UTF8

$conn.Close()
Write-Host ""
Write-Host "CSVs salvos em $OUT_DIR" -ForegroundColor Green
