# ════════════════════════════════════════════════════════════════
# Sync Azure Blob (CITTATI JSON_VIAGENS) → Supabase
# Janela fixa: últimos 15 dias (sempre sobrescreve)
# Local no servidor: C:\sync_praxio\sync-viagens-azure.ps1
# Task Scheduler: rodar 1x ao dia (ex: 06:00)
# Pré-req: Install-Module -Name Az.Storage -Scope CurrentUser -Force
# ════════════════════════════════════════════════════════════════

# ── Configuração ─────────────────────────────────────────────────
$CONN_STRING  = "DefaultEndpointsProtocol=https;AccountName=appfuncgenericstor;AccountKey=COLE_AQUI;EndpointSuffix=core.windows.net"
$CONTAINER    = "1-raw"
$BLOB_PREFIX  = "CITTATI/JSON_VIAGENS"
$SUPABASE_URL = "https://yxwxcxdegkvjvwchemsm.supabase.co"
$SUPABASE_KEY = "sb_publishable_SvC1D0cMk94sZ_9kYv41QQ_RJVrSuUV"
$BATCH        = 400
$JANELA_DIAS  = 15

# Mapeamento código-arquivo → UUID da garagem no Supabase
# UUID: Supabase → Table Editor → garagens → copie o id
$GARAGEM_MAP = @{
    "JTP01" = "UUID_GARAGEM_01_AQUI"
    # "JTP02" = "UUID_GARAGEM_02_AQUI"
}

# ── Helpers ───────────────────────────────────────────────────────
function Supabase-Delete($tabela, $filtros) {
    $qs = ($filtros.GetEnumerator() | ForEach-Object { "$($_.Key)=eq.$($_.Value)" }) -join "&"
    $uri = "$SUPABASE_URL/rest/v1/${tabela}?${qs}"
    $hdr = @{
        "apikey"        = $SUPABASE_KEY
        "Authorization" = "Bearer $SUPABASE_KEY"
        "Prefer"        = "return=minimal"
    }
    try {
        Invoke-RestMethod -Method DELETE -Uri $uri -Headers $hdr | Out-Null
    } catch {
        Write-Warning "Erro no DELETE: $_"
    }
}

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
        $lote = $registros[$i..([Math]::Min($i + $BATCH - 1, $registros.Count - 1))]
        try {
            Invoke-RestMethod -Method POST -Uri $uri -Headers $hdr -Body ($lote | ConvertTo-Json -Depth 3) | Out-Null
            Write-Host "    Inserido lote: $($lote.Count) registros" -ForegroundColor Cyan
        } catch {
            Write-Warning "Erro no INSERT lote $i : $_"
        }
    }
}

function To-DataISO($str) {
    if ($str -match '(\d{2})/(\d{2})/(\d{4})') { return "$($matches[3])-$($matches[2])-$($matches[1])" }
    if ($str -match '(\d{4}-\d{2}-\d{2})') { return $matches[1] }
    return $null
}

# ── Calcula janela e meses necessários ────────────────────────────
$hoje       = Get-Date
$dataInicio = $hoje.AddDays(-$JANELA_DIAS).ToString("yyyy-MM-dd")
$dataFim    = $hoje.ToString("yyyy-MM-dd")

# Descobre quais meses cobrem a janela de 15 dias
$mesesNecessarios = @()
$d = $hoje.AddDays(-$JANELA_DIAS)
while ($d -le $hoje) {
    $chave = $d.ToString("MM_yyyy")
    if ($mesesNecessarios -notcontains $chave) { $mesesNecessarios += $chave }
    $d = $d.AddMonths(1)
}
$mesesNecessarios += $hoje.ToString("MM_yyyy")  # garante mês atual
$mesesNecessarios = $mesesNecessarios | Select-Object -Unique

Write-Host "Janela: $dataInicio → $dataFim | Meses: $($mesesNecessarios -join ', ')" -ForegroundColor Yellow

# ── Main ──────────────────────────────────────────────────────────
Import-Module Az.Storage -ErrorAction Stop
$ctx    = New-AzStorageContext -ConnectionString $CONN_STRING
$tmpDir = Join-Path $env:TEMP "jtp_viagens_sync"
New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
$agora  = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")

foreach ($cod in $GARAGEM_MAP.Keys) {
    $gid = $GARAGEM_MAP[$cod]
    Write-Host "`n══ Garagem $cod ══════════════════════════════════" -ForegroundColor Yellow

    # 1. Apaga os últimos 15 dias desta garagem no Supabase
    Write-Host "  Limpando registros $dataInicio → $dataFim..."
    $uri = "$SUPABASE_URL/rest/v1/viagens_resumo?garagem_cod=eq.$cod&data=gte.$dataInicio&data=lte.$dataFim"
    $hdr = @{ "apikey" = $SUPABASE_KEY; "Authorization" = "Bearer $SUPABASE_KEY"; "Prefer" = "return=minimal" }
    try { Invoke-RestMethod -Method DELETE -Uri $uri -Headers $hdr | Out-Null } catch { Write-Warning "Delete: $_" }

    # 2. Baixa e agrega os arquivos do período
    $registros = [System.Collections.Generic.List[object]]::new()

    foreach ($mesAno in $mesesNecessarios) {
        $blob = "$BLOB_PREFIX/${cod}_${mesAno}.json"
        $tmp  = Join-Path $tmpDir "${cod}_${mesAno}.json"

        Write-Host "  Baixando $blob..." -NoNewline
        try {
            Get-AzStorageBlobContent -Container $CONTAINER -Blob $blob -Destination $tmp -Context $ctx -Force -ErrorAction Stop | Out-Null
            Write-Host " OK" -ForegroundColor Green
        } catch {
            Write-Host " não encontrado" -ForegroundColor DarkGray
            continue
        }

        $json    = Get-Content $tmp -Raw -Encoding UTF8 | ConvertFrom-Json
        $viagens = $json.viagens

        # Filtra só os últimos 15 dias
        $viagens = $viagens | Where-Object {
            $d = To-DataISO $_.data
            $d -ge $dataInicio -and $d -le $dataFim
        }
        Write-Host "  $($viagens.Count) viagens no período — agregando..."

        # Agrega: (data, linha, veiculo, motorista) → contagens
        $grupos = $viagens | Group-Object {
            $d = To-DataISO $_.data
            $m = if ($_.motorista) { $_.motorista } else { "SEM_MOTORISTA" }
            "$d|$($_.linha)|$($_.veiculo)|$m"
        }

        foreach ($g in $grupos) {
            $p = $g.Name -split '\|'
            if (-not $p[0]) { continue }

            $realizadas = ($g.Group | Where-Object { $null -ne $_.inicioRealizado }).Count

            $registros.Add([PSCustomObject]@{
                garagem_id          = $gid
                garagem_cod         = $cod
                data                = $p[0]
                linha               = $p[1]
                veiculo             = $p[2]
                motorista_cod       = $p[3]
                viagens_programadas = $g.Count
                viagens_realizadas  = $realizadas
                updated_at          = $agora
            })
        }
    }

    # 3. Insere os dados frescos
    Write-Host "  Inserindo $($registros.Count) registros no Supabase..."
    Supabase-Insert "viagens_resumo" $registros
    Write-Host "  Garagem $cod concluída!" -ForegroundColor Green
}

Remove-Item $tmpDir -Recurse -Force
Write-Host "`n✅ Sync concluído — janela: $dataInicio → $dataFim" -ForegroundColor Green
