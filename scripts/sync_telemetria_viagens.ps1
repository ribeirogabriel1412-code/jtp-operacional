# Sync Telemetria (JSON mensal do SharePoint) -> Supabase
# Fonte: pasta local sincronizada do SharePoint (OneDrive), 1 arquivo por mes.
# Padrao: apaga a competencia (mes) processada e reinsere ("delete+insert"),
# igual ao sync-viagens-azure.ps1.
# Rodar manualmente por enquanto (sem Task Scheduler ainda).

# -- Configuracao --------------------------------------------------
$SUPABASE_URL = "https://yxwxcxdegkvjvwchemsm.supabase.co"
$SUPABASE_KEY = "sb_publishable_SvC1D0cMk94sZ_9kYv41QQ_RJVrSuUV"
$BATCH        = 400

$PASTA_TELEMETRIA = "C:\Users\gabriel.ribeiro\JTP TRANSPORTES, SERVICOS, GERENCIAMENTO E RECURSOS HUMANOS LTDA\Operações Seguras - Documentos\N2 - Operações Seguras\3_Portal de Operações Seguras\Consumo de Combustível\APIs\TELEMETRIA\Consolidado"

# Arquivo(s) a processar nesta rodada. Ajuste para reprocessar outro mes.
$ARQUIVOS = @(
    "26 - 07 - Julho - Telemetria.json"
)

# -- Helpers -------------------------------------------------------
function Supabase-Insert($tabela, $registros) {
    if ($registros.Count -eq 0) { return }
    $uri = "$SUPABASE_URL/rest/v1/$tabela"
    $hdr = @{
        "apikey"        = $SUPABASE_KEY
        "Authorization" = "Bearer $SUPABASE_KEY"
        "Content-Type"  = "application/json"
        "Prefer"        = "return=minimal"
    }
    for ($i = 0; $i -lt $registros.Count; $i += $BATCH) {
        $fim  = [Math]::Min($i + $BATCH - 1, $registros.Count - 1)
        $lote = $registros[$i..$fim]
        try {
            Invoke-RestMethod -Method POST -Uri $uri -Headers $hdr -Body ($lote | ConvertTo-Json -Depth 3) | Out-Null
            Write-Host "    Lote inserido: $($lote.Count) registros ($($i + $lote.Count)/$($registros.Count))" -ForegroundColor Cyan
        } catch {
            Write-Warning "Erro INSERT lote $i : $_"
        }
    }
}

function ParseNum($v) {
    if ($null -eq $v -or $v -eq "") { return $null }
    try { return [double]$v } catch { return $null }
}

# Nome do arquivo: "26 - 07 - Julho - Telemetria.json" -> competencia "2026-07"
function CompetenciaDoArquivo($nomeArquivo) {
    if ($nomeArquivo -match '^(\d{2})\s*-\s*(\d{2})\s*-') {
        return "20$($matches[1])-$($matches[2])"
    }
    return $null
}

# -- Main ----------------------------------------------------------
foreach ($arquivo in $ARQUIVOS) {
    $competencia = CompetenciaDoArquivo $arquivo
    if (-not $competencia) {
        Write-Warning "Nao consegui extrair competencia de '$arquivo', pulando."
        continue
    }

    $caminho = Join-Path $PASTA_TELEMETRIA $arquivo
    if (-not (Test-Path $caminho)) {
        Write-Warning "Arquivo nao encontrado: $caminho"
        continue
    }

    Write-Host ""
    Write-Host "=== $arquivo (competencia $competencia) ===" -ForegroundColor Yellow

    Write-Host "  Lendo JSON..."
    $viagens = Get-Content $caminho -Raw -Encoding UTF8 | ConvertFrom-Json
    Write-Host "  $($viagens.Count) registros no arquivo"

    # 1. Apaga a competencia (mes) antes de reinserir
    Write-Host "  Limpando competencia $competencia no Supabase..."
    $delUri = "$SUPABASE_URL/rest/v1/telemetria_viagens?competencia=eq.$competencia"
    $delHdr = @{ "apikey" = $SUPABASE_KEY; "Authorization" = "Bearer $SUPABASE_KEY"; "Prefer" = "return=minimal" }
    try { Invoke-RestMethod -Method DELETE -Uri $delUri -Headers $delHdr | Out-Null } catch { Write-Warning "Delete: $_" }

    # 2. Monta os registros no formato da tabela
    $registros = [System.Collections.Generic.List[object]]::new()
    $agora = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")

    foreach ($v in $viagens) {
        if (-not $v.start_time -or -not $v.device_id) { continue }

        $registros.Add([PSCustomObject]@{
            competencia                    = $competencia
            prefixo                        = if ($v.PREFIXO) { $v.PREFIXO.Trim() } else { $null }
            placa                          = $v.unit_label
            group_name                     = $v.group_name
            subgroup_name                  = $v.subgroup_name
            device_id                      = $v.device_id
            vehicle_id                     = $v.vehicle_id
            driver_name                    = $v.driver_name
            matricula                      = $v.matricula
            cnh                            = $v.cnh
            identifier                     = $v.identifier
            start_time                     = $v.start_time
            end_time                       = $v.end_time
            start_odometer                 = ParseNum $v.start_odometer
            end_odometer                   = ParseNum $v.end_odometer
            distance_traveled              = ParseNum $v.distance_traveled
            fuel_used                      = ParseNum $v.fuel_used
            total_time                     = ParseNum $v.total_time
            time_over_speed                = ParseNum $v.time_over_speed
            time_cluth_excess              = ParseNum $v.time_cluth_excess
            time_stopped                   = ParseNum $v.time_stopped
            time_moving                    = ParseNum $v.time_moving
            time_engine_off                = ParseNum $v.time_engine_off
            time_blue                      = ParseNum $v.time_blue
            time_eco_roll                  = ParseNum $v.time_eco_roll
            time_stop_engine_on_productive = ParseNum $v.time_stop_engine_on_productive
            time_low_speed                 = ParseNum $v.time_low_speed
            time_green                     = ParseNum $v.time_green
            time_extra_eco                 = ParseNum $v.time_extra_eco
            time_yellow                    = ParseNum $v.time_yellow
            time_red                       = ParseNum $v.time_red
            time_stop_engine_on            = ParseNum $v.time_stop_engine_on
            time_stop_accel                = ParseNum $v.time_stop_accel
            time_tolerancia                = ParseNum $v.time_tolerancia
            time_inercia                   = ParseNum $v.time_inercia
            time_banguela                  = ParseNum $v.time_banguela
            updated_at                     = $agora
        })
    }

    # 3. Insere dados frescos
    Write-Host "  Inserindo $($registros.Count) registros no Supabase..."
    Supabase-Insert "telemetria_viagens" $registros
    Write-Host "  $arquivo concluido!" -ForegroundColor Green
}

Write-Host ""
Write-Host "Sync de telemetria concluido!" -ForegroundColor Green
