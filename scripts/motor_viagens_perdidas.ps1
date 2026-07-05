# Motor de Viagens Perdidas + Pontualidade -- JTP Transportes
# Le os JSONs de viagem do Azure Blob (CITTATI) num periodo e calcula,
# por veiculo e por linha, quantas viagens foram programadas x realizadas x perdidas,
# e das realizadas, quantas foram adiantadas x pontuais x atrasadas.
# Tolerancia de pontualidade: +-11 minutos (calibrado em 2026-07-04 contra o painel oficial,
# comparando 9 combos linha+motorista de Porto Velho/junho -- bateu exato em todos, exceto 1
# que ficou pra investigar. NAO e +-10 como o sync-viagens-azure.ps1 antigo assume.
#
# NAO grava nada no Supabase -- essa e' a etapa de validacao manual dos calculos.
# Depois de conferido, decidimos onde o resultado mora (Supabase, endpoint sob demanda, etc).
#
# Local sugerido no servidor: C:\sync_praxio\motor_viagens_perdidas.ps1
# Pre-req: Install-Module -Name Az.Storage -Scope CurrentUser -Force
#
# USO:
#   .\motor_viagens_perdidas.ps1 -DataInicio "2026-06-01" -DataFim "2026-07-04"
#   .\motor_viagens_perdidas.ps1 -Garagem "carlos.jtp" -DataInicio "2026-06-01" -DataFim "2026-06-30"
#   (sem parametros, roda mes passado + mes atual ate hoje, todas as garagens do mapa)

param(
    [string]$DataInicio,
    [string]$DataFim,
    [string]$Garagem  # prefixo do GARAGEM_MAP (ex: "Jessica", "carlos.jtp") -- vazio = todas
)

# -- Configuracao --------------------------------------------------
# A connection string real vem de $env:JTP_AZURE_STORAGE_CONN (setada por um script
# local fora do git, ex: scripts/run-motor-viagens.local.ps1). Nunca colar a chave aqui.
$CONN_STRING = if ($env:JTP_AZURE_STORAGE_CONN) { $env:JTP_AZURE_STORAGE_CONN } else { "DefaultEndpointsProtocol=https;AccountName=appfuncgenericstor;AccountKey=COLE_AQUI;EndpointSuffix=core.windows.net" }
$CONTAINER   = "1-raw"
$BLOB_PREFIX = "CITTATI/JSON_VIAGENS"
$OUT_DIR     = "C:\sync_praxio\relatorios"

# Prefixo do arquivo blob -> garagem
# (mesmo mapa do sync-viagens-azure.ps1 -- completar conforme novas garagens forem cadastradas)
$GARAGEM_MAP = @{
    "Jessica"    = @{ cod = "JTP01" }  # Porto Velho
    "carlos.jtp" = @{ cod = "JTP02" }  # Braganca
}

# -- Periodo ---------------------------------------------------------
if (-not $DataFim) { $DataFim = (Get-Date).ToString("yyyy-MM-dd") }
if (-not $DataInicio) {
    $hoje = Get-Date
    $DataInicio = (Get-Date -Year $hoje.Year -Month $hoje.Month -Day 1).AddMonths(-1).ToString("yyyy-MM-dd")
}

$inicio = [datetime]::ParseExact($DataInicio, "yyyy-MM-dd", $null)
$fim    = [datetime]::ParseExact($DataFim, "yyyy-MM-dd", $null)

Write-Host "Motor de Viagens Perdidas" -ForegroundColor Yellow
Write-Host "Periodo: $DataInicio ate $DataFim" -ForegroundColor Yellow

$dias = @()
$d = $inicio
while ($d -le $fim) { $dias += $d; $d = $d.AddDays(1) }

# -- Helper: parse data/hora (mesmo padrao do sync existente) -------
function Parse-DataHora($str) {
    if (-not $str) { return $null }
    try {
        if ($str -match '(\d{2})/(\d{2})/(\d{4}) (\d{2}):(\d{2}):(\d{2})') {
            return [datetime]::new([int]$matches[3],[int]$matches[2],[int]$matches[1],[int]$matches[4],[int]$matches[5],[int]$matches[6])
        }
    } catch { return $null }
    return $null
}

# Classifica uma viagem realizada em adiantada/pontual/atrasada (tolerancia +-11min)
function Classifica-Pontualidade($trip) {
    $prog = Parse-DataHora $trip.inicioProgramado
    $real = Parse-DataHora $trip.inicioRealizado
    if (-not $prog -or -not $real) { return $null }
    $diff = ($real - $prog).TotalMinutes
    if     ($diff -lt -11) { return "adiantada" }
    elseif ($diff -le  11) { return "pontual"   }
    else                   { return "atrasada"  }
}

# -- Main ------------------------------------------------------------
Import-Module Az.Storage -ErrorAction Stop
$ctx    = New-AzStorageContext -ConnectionString $CONN_STRING
$tmpDir = "$OUT_DIR\tmp"
New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
New-Item -ItemType Directory -Path $OUT_DIR -Force | Out-Null

# Linha de detalhe: 1 por (garagem, dia, linha, veiculo) -- so viagens com carro atribuido
$detalhe = [System.Collections.Generic.List[object]]::new()
# Linha por (garagem, dia, linha) -- TODAS as viagens, mesmo sem carro atribuido
# (viagem que nunca saiu as vezes fica sem veiculo no registro; precisa entrar no total/por-linha)
$porLinhaDia = [System.Collections.Generic.List[object]]::new()

$prefixosRodar = if ($Garagem) { @($Garagem) } else { $GARAGEM_MAP.Keys }

foreach ($prefixo in $prefixosRodar) {
    if (-not $GARAGEM_MAP.ContainsKey($prefixo)) {
        Write-Warning "Garagem '$prefixo' nao esta no GARAGEM_MAP -- pulando."
        continue
    }
    $cod = $GARAGEM_MAP[$prefixo].cod
    Write-Host ""
    Write-Host "=== $prefixo ($cod) ===" -ForegroundColor Yellow

    foreach ($dia in $dias) {
        $sufixo  = $dia.ToString("dd_MM_yyyy")
        $blob    = "$BLOB_PREFIX/$prefixo $sufixo.json"
        $tmp     = "$tmpDir\${prefixo}_${sufixo}.json"
        $dataISO = $dia.ToString("yyyy-MM-dd")

        try {
            Get-AzStorageBlobContent -Container $CONTAINER -Blob $blob -Destination $tmp -Context $ctx -Force -ErrorAction Stop | Out-Null
        } catch {
            continue  # dia sem arquivo (ex: dia sem operacao)
        }

        $json    = Get-Content $tmp -Raw -Encoding UTF8 | ConvertFrom-Json
        # So conta viagem comercial real -- "Saida de Garagem" e "Recolhe" sao
        # movimentacao de patio, nao viagem de linha, e tem taxa de "nao realizada"
        # artificialmente alta (confirmado em amostra: Recolhe ~25% vs Viagem Normal ~0,2%)
        $viagens = @($json.viagens | Where-Object { $_.atividade -eq "Viagem Normal" })
        if ($viagens.Count -eq 0) { continue }

        # -- Agregado por linha (TODAS as viagens, com ou sem carro atribuido) --
        $gruposLinha = $viagens | Group-Object linha
        foreach ($gl in $gruposLinha) {
            if (-not $gl.Name) { continue }
            # @() forca contexto de array -- sem isso, quando so ha 1 resultado o Where-Object
            # "desembrulha" pra objeto solto e .Count vira $null (bug real ja encontrado: fazia
            # linhas de 1 viagem/dia, como 117.1/110.1/215.1, sumirem da soma de realizadas)
            $realizadasTrips = @($gl.Group | Where-Object { $null -ne $_.inicioRealizado })
            $classificadas   = @($realizadasTrips | ForEach-Object { Classifica-Pontualidade $_ })
            $pontuais        = @($classificadas | Where-Object { $_ -eq "pontual"   }).Count
            $adiantadas      = @($classificadas | Where-Object { $_ -eq "adiantada" }).Count
            $atrasadas       = @($classificadas | Where-Object { $_ -eq "atrasada"  }).Count
            $porLinhaDia.Add([PSCustomObject]@{
                garagem_cod = $cod
                data        = $dataISO
                linha       = $gl.Name
                programadas = $gl.Count
                realizadas  = $realizadasTrips.Count
                perdidas    = $gl.Count - $realizadasTrips.Count
                pontuais    = $pontuais
                adiantadas  = $adiantadas
                atrasadas   = $atrasadas
            })
        }

        # -- Detalhe por linha+veiculo (so viagens com carro atribuido) --
        $grupos = $viagens | Group-Object { $_.linha + "~" + $_.veiculo }

        foreach ($g in $grupos) {
            $p = $g.Name -split "~"
            if (-not $p[0] -or -not $p[1]) { continue }

            $realizadasTrips = @($g.Group | Where-Object { $null -ne $_.inicioRealizado })
            $classificadas   = @($realizadasTrips | ForEach-Object { Classifica-Pontualidade $_ })
            $pontuais        = @($classificadas | Where-Object { $_ -eq "pontual"   }).Count
            $adiantadas      = @($classificadas | Where-Object { $_ -eq "adiantada" }).Count
            $atrasadas       = @($classificadas | Where-Object { $_ -eq "atrasada"  }).Count
            $programadas     = $g.Count
            $perdidas        = $programadas - $realizadasTrips.Count

            $detalhe.Add([PSCustomObject]@{
                garagem_cod = $cod
                data        = $dataISO
                linha       = $p[0]
                veiculo     = $p[1]
                programadas = $programadas
                realizadas  = $realizadasTrips.Count
                perdidas    = $perdidas
                pontuais    = $pontuais
                adiantadas  = $adiantadas
                atrasadas   = $atrasadas
            })
        }
    }
}

Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue

if ($porLinhaDia.Count -eq 0) {
    Write-Host "Nenhum dado encontrado no periodo." -ForegroundColor Red
    return
}

# -- Resumo por veiculo (todo o periodo) ------------------------------
$porVeiculo = $detalhe | Group-Object veiculo | ForEach-Object {
    $prog = ($_.Group | Measure-Object programadas -Sum).Sum
    $real = ($_.Group | Measure-Object realizadas -Sum).Sum
    $perd = $prog - $real
    $pont = ($_.Group | Measure-Object pontuais -Sum).Sum
    [PSCustomObject]@{
        veiculo         = $_.Name
        programadas     = $prog
        realizadas      = $real
        perdidas        = $perd
        pct_perda       = if ($prog -gt 0) { [Math]::Round(($perd / $prog) * 100, 1) } else { 0 }
        pontuais        = $pont
        adiantadas      = ($_.Group | Measure-Object adiantadas -Sum).Sum
        atrasadas       = ($_.Group | Measure-Object atrasadas -Sum).Sum
        pct_pontualidade = if ($real -gt 0) { [Math]::Round(($pont / $real) * 100, 1) } else { 0 }
    }
} | Sort-Object pct_perda -Descending

# -- Resumo por linha (todo o periodo, todas as viagens) --------------
$porLinha = $porLinhaDia | Group-Object linha | ForEach-Object {
    $prog = ($_.Group | Measure-Object programadas -Sum).Sum
    $real = ($_.Group | Measure-Object realizadas -Sum).Sum
    $perd = $prog - $real
    $pont = ($_.Group | Measure-Object pontuais -Sum).Sum
    [PSCustomObject]@{
        linha           = $_.Name
        programadas     = $prog
        realizadas      = $real
        perdidas        = $perd
        pct_perda       = if ($prog -gt 0) { [Math]::Round(($perd / $prog) * 100, 1) } else { 0 }
        pontuais        = $pont
        adiantadas      = ($_.Group | Measure-Object adiantadas -Sum).Sum
        atrasadas       = ($_.Group | Measure-Object atrasadas -Sum).Sum
        pct_pontualidade = if ($real -gt 0) { [Math]::Round(($pont / $real) * 100, 1) } else { 0 }
    }
} | Sort-Object pct_pontualidade

# -- Totais gerais (todas as viagens, com ou sem carro atribuido) ------
$totalProg = ($porLinhaDia | Measure-Object programadas -Sum).Sum
$totalReal = ($porLinhaDia | Measure-Object realizadas -Sum).Sum
$totalPerd = $totalProg - $totalReal
$totalPont = ($porLinhaDia | Measure-Object pontuais -Sum).Sum
$totalAdia = ($porLinhaDia | Measure-Object adiantadas -Sum).Sum
$totalAtra = ($porLinhaDia | Measure-Object atrasadas -Sum).Sum

Write-Host ""
Write-Host "=== TOTAL DO PERIODO ===" -ForegroundColor Cyan
Write-Host "Programadas: $totalProg | Realizadas: $totalReal | Perdidas: $totalPerd ($([Math]::Round(($totalPerd/$totalProg)*100,1))%)" -ForegroundColor Cyan
Write-Host "Pontualidade (das realizadas): Pontuais $totalPont ($([Math]::Round(($totalPont/$totalReal)*100,1))%) | Adiantadas $totalAdia | Atrasadas $totalAtra" -ForegroundColor Cyan
Write-Host ""
Write-Host "--- Top 10 veiculos com mais perda ---" -ForegroundColor Yellow
$porVeiculo | Select-Object -First 10 | Format-Table -AutoSize
Write-Host "--- Top 10 linhas com menos pontualidade ---" -ForegroundColor Yellow
$porLinha | Select-Object -First 10 | Format-Table -AutoSize

# -- Exporta CSVs para conferencia manual ------------------------------
$sufixoArq = "$($DataInicio)_a_$($DataFim)"
$detalhe    | Export-Csv -Path "$OUT_DIR\viagens_detalhe_$sufixoArq.csv"    -NoTypeInformation -Encoding UTF8
$porVeiculo | Export-Csv -Path "$OUT_DIR\viagens_por_veiculo_$sufixoArq.csv" -NoTypeInformation -Encoding UTF8
$porLinha   | Export-Csv -Path "$OUT_DIR\viagens_por_linha_$sufixoArq.csv"   -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "CSVs salvos em $OUT_DIR" -ForegroundColor Green
