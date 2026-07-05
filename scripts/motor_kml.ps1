# Motor de Km/L -- JTP Transportes
# Le a view GLOBUS868.VW_LANCAMENTOABASTECIMENTO (Oracle) num periodo e calcula,
# por veiculo e por linha, o Km/L real do periodo.
#
# IMPORTANTE: calculo sempre SUM(km) / SUM(litros) -- NUNCA AVG(KM_POR_L).
# Media das medias distorce o resultado (validado com o export CTAPLUS em 2026-07-04:
# media ingenua deu 11,1 km/l, o real ponderado era 2,51 km/l).
#
# NAO grava nada no Supabase ainda -- essa e' a etapa de validacao manual dos calculos.
#
# RODAR NO SERVIDOR (unico lugar com IP liberado no ODBC GLOBUSSERVER).
# Senha vem de $env:JTP_ORACLE_PWD (setar antes de rodar, nunca colar aqui).
#
# USO:
#   .\motor_kml.ps1 -DataInicio "2026-06-01" -DataFim "2026-06-30"
#   .\motor_kml.ps1 -Garagem PVH
#   (sem parametros, roda mes passado + mes atual ate hoje, todas as garagens)

param(
    [string]$DataInicio,
    [string]$DataFim,
    [string]$Garagem  # "PVH" (Porto Velho, prefixo 02.xxx) ou "BRA" (Braganca, 03.xxx) -- vazio = todas
)

# Mapa garagem -> prefixo de frota (mesmo padrao ja confirmado no motor de viagens:
# Porto Velho = 02.xxx, Braganca = 03.xxx)
$PREFIXO_GARAGEM = @{ "PVH" = "02"; "BRA" = "03" }

$DSN = "GLOBUSSERVER"
$UID = if ($env:JTP_ORACLE_UID) { $env:JTP_ORACLE_UID } else { "CONSULTA868" }
$PWD_ORACLE = if ($env:JTP_ORACLE_PWD) { $env:JTP_ORACLE_PWD } else { "COLE_AQUI" }
$OUT_DIR = "C:\sync_praxio\relatorios"
$TABELA = "GLOBUS868.VW_LANCAMENTOABASTECIMENTO"

if (-not $DataFim) { $DataFim = (Get-Date).ToString("yyyy-MM-dd") }
if (-not $DataInicio) {
    $hoje = Get-Date
    $DataInicio = (Get-Date -Year $hoje.Year -Month $hoje.Month -Day 1).AddMonths(-1).ToString("yyyy-MM-dd")
}

$connStr = "DSN=$DSN;UID=$UID;PWD=$PWD_ORACLE"
New-Item -ItemType Directory -Path $OUT_DIR -Force | Out-Null

Write-Host "Motor de Km/L" -ForegroundColor Yellow
Write-Host "Periodo: $DataInicio ate $DataFim" -ForegroundColor Yellow

Add-Type -AssemblyName System.Data
$conn = New-Object System.Data.Odbc.OdbcConnection
$conn.ConnectionString = $connStr
$conn.Open()

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

# Converte o prefixo bruto do Oracle pro formato da frota (mesma regra ja usada
# no sync do PRAXIO: pega os ultimos 5 digitos, ponto depois do 2o -- "0002190" -> "02.190")
function Formata-Prefixo($raw) {
    $s = "$raw".Trim()
    if ($s.Length -ge 5 -and $s -match '^\d+$') {
        $last5 = $s.Substring($s.Length - 5)
        return $last5.Substring(0,2) + "." + $last5.Substring(2)
    }
    return $s
}

# -- Query principal ---------------------------------------------------
# Filtra registros invalidos na origem: sem placa, km<=0 ou litros<=0 sao
# lixo de medicao (mesmo padrao do "MAN002" achado no Excel CTAPLUS) e nao
# entram no calculo.
$sql = @"
SELECT PREFIXO, PLACA, GARAGEM, NOME_LINHA, NOME_MOTORISTA,
       KM_PERCORRIDO, KM_POR_L, DATA_ABASTECIMENTO
FROM $TABELA
WHERE DATA_ABASTECIMENTO >= TO_DATE('$DataInicio','YYYY-MM-DD')
  AND DATA_ABASTECIMENTO <= TO_DATE('$DataFim','YYYY-MM-DD') + 1
  AND PLACA IS NOT NULL
  AND KM_PERCORRIDO > 0
  AND KM_POR_L > 0
"@

Write-Host "Consultando Oracle..." -ForegroundColor Cyan
$linhas = Roda-Query $sql 180
Write-Host "$($linhas.Count) abastecimentos validos encontrados (antes do filtro de garagem)." -ForegroundColor Green

if ($linhas.Count -eq 0) {
    Write-Host "Nenhum dado encontrado no periodo." -ForegroundColor Red
    $conn.Close()
    return
}

# Litro implicito derivado do KM_POR_L ja calculado e validado pela view --
# evita depender da escala ambigua de QUANTIDADE_COMBUSTIVEL (testado e nao
# bateu com fator fixo de escala em todos os registros).
foreach ($l in $linhas) {
    $l | Add-Member -NotePropertyName LITROS_IMPLICITO -NotePropertyValue ($l.KM_PERCORRIDO / $l.KM_POR_L)
    $l | Add-Member -NotePropertyName PREFIXO_FROTA -NotePropertyValue (Formata-Prefixo $l.PREFIXO)
}

# -- Filtro por garagem (via prefixo de frota, nao pelo codigo GARAGEM cru
# do Oracle -- ainda nao confirmamos o que cada codigo numerico significa
# nessa view especifica) --------------------------------------------------
if ($Garagem) {
    if (-not $PREFIXO_GARAGEM.ContainsKey($Garagem)) {
        Write-Warning "Garagem '$Garagem' desconhecida. Use PVH ou BRA."
    } else {
        $pref = $PREFIXO_GARAGEM[$Garagem]
        $linhas = $linhas | Where-Object { $_.PREFIXO_FROTA -like "$pref.*" }
        Write-Host "Filtrado pra $Garagem (prefixo $pref.xxx): $($linhas.Count) abastecimentos." -ForegroundColor Green
    }
}

if ($linhas.Count -eq 0) {
    Write-Host "Nenhum dado apos filtro de garagem." -ForegroundColor Red
    $conn.Close()
    return
}

# -- Agregado por veiculo (PREFIXO) -------------------------------------
# MINIMO_ABAST filtra veiculos com pouquissimo abastecimento no periodo --
# esses geralmente sao codigo administrativo/terceiro, nao onibus da frota
# ativa (confirmado por Daniel: os "piores Km/L" da 1a rodada eram lixo, so
# 1 abastecimento no periodo inteiro, prefixo fora do padrao 0X.XXX da frota).
$MINIMO_ABAST = 15

$porVeiculo = $linhas | Group-Object PREFIXO | ForEach-Object {
    $km = ($_.Group | Measure-Object KM_PERCORRIDO -Sum).Sum
    $lt = ($_.Group | Measure-Object LITROS_IMPLICITO -Sum).Sum
    [PSCustomObject]@{
        prefixo      = $_.Name
        prefixo_frota = $_.Group[0].PREFIXO_FROTA
        placa        = $_.Group[0].PLACA
        abastecimentos = $_.Count
        km_total     = [Math]::Round($km, 1)
        litros_total = [Math]::Round($lt, 2)
        kml          = if ($lt -gt 0) { [Math]::Round($km / $lt, 2) } else { 0 }
    }
} | Sort-Object kml

$porVeiculoReal = $porVeiculo | Where-Object { $_.abastecimentos -ge $MINIMO_ABAST }

# -- Agregado por linha ---------------------------------------------------
$porLinha = $linhas | Where-Object { $_.NOME_LINHA } | Group-Object NOME_LINHA | ForEach-Object {
    $km = ($_.Group | Measure-Object KM_PERCORRIDO -Sum).Sum
    $lt = ($_.Group | Measure-Object LITROS_IMPLICITO -Sum).Sum
    [PSCustomObject]@{
        linha        = $_.Name
        abastecimentos = $_.Count
        km_total     = [Math]::Round($km, 1)
        litros_total = [Math]::Round($lt, 2)
        kml          = if ($lt -gt 0) { [Math]::Round($km / $lt, 2) } else { 0 }
    }
} | Sort-Object kml

# -- Total geral (SUM/SUM, nunca AVG das medias individuais) -------------
$totalKm = ($linhas | Measure-Object KM_PERCORRIDO -Sum).Sum
$totalLt = ($linhas | Measure-Object LITROS_IMPLICITO -Sum).Sum
$kmlGeral = if ($totalLt -gt 0) { [Math]::Round($totalKm / $totalLt, 2) } else { 0 }

Write-Host ""
Write-Host "=== TOTAL DO PERIODO ===" -ForegroundColor Cyan
Write-Host "Km rodado: $([Math]::Round($totalKm,0)) | Litros: $([Math]::Round($totalLt,0)) | Km/L: $kmlGeral" -ForegroundColor Cyan
Write-Host ""
Write-Host "--- Top 10 veiculos com PIOR Km/L (so frota real, >= $MINIMO_ABAST abastecimentos) ---" -ForegroundColor Yellow
$porVeiculoReal | Select-Object -First 10 prefixo_frota,placa,abastecimentos,km_total,litros_total,kml | Format-Table -AutoSize
Write-Host "--- Top 10 linhas com PIOR Km/L ---" -ForegroundColor Yellow
$porLinha | Select-Object -First 10 | Format-Table -AutoSize
Write-Host "($($porVeiculo.Count - $porVeiculoReal.Count) codigos com menos de $MINIMO_ABAST abastecimentos foram descartados do ranking -- provavelmente nao sao frota ativa)" -ForegroundColor DarkGray

# -- Exporta CSVs para conferencia manual --------------------------------
$sufixo = "$($DataInicio)_a_$($DataFim)"
$porVeiculo     | Export-Csv -Path "$OUT_DIR\kml_por_veiculo_todos_$sufixo.csv" -NoTypeInformation -Encoding UTF8
$porVeiculoReal | Export-Csv -Path "$OUT_DIR\kml_por_veiculo_frota_$sufixo.csv" -NoTypeInformation -Encoding UTF8
$porLinha       | Export-Csv -Path "$OUT_DIR\kml_por_linha_$sufixo.csv"         -NoTypeInformation -Encoding UTF8

$conn.Close()
Write-Host ""
Write-Host "CSVs salvos em $OUT_DIR" -ForegroundColor Green
