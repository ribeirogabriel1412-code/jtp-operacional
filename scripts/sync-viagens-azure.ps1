# Sync Azure Blob (CITTATI JSON_VIAGENS) -> Supabase
# Janela fixa: ultimos 15 dias (sempre sobrescreve)
# Local no servidor: C:\sync_praxio\sync-viagens-azure.ps1
# Task Scheduler: rodar 1x ao dia (ex: 06:00)
# Pre-req: Install-Module -Name Az.Storage -Scope CurrentUser -Force

# -- Configuracao --------------------------------------------------
$CONN_STRING  = "DefaultEndpointsProtocol=https;AccountName=appfuncgenericstor;AccountKey=COLE_AQUI;EndpointSuffix=core.windows.net"
$CONTAINER    = "1-raw"
$BLOB_PREFIX  = "CITTATI/JSON_VIAGENS"
$SUPABASE_URL = "https://yxwxcxdegkvjvwchemsm.supabase.co"
$SUPABASE_KEY = "sb_publishable_SvC1D0cMk94sZ_9kYv41QQ_RJVrSuUV"
$BATCH        = 400
$JANELA_DIAS  = 7

# Prefixo do arquivo blob -> garagem no Supabase
# Formato dos arquivos: "Jessica DD_MM_YYYY.json"
$GARAGEM_MAP = @{
    "Jessica" = @{ gid = "aaaaaaaa-0001-0000-0000-000000000001"; cod = "JTP01" }
    # "carlos.jtp" = @{ gid = "UUID_BRAGANCA_AQUI"; cod = "JTP02" }
}

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
            Write-Host "    Lote inserido: $($lote.Count) registros" -ForegroundColor Cyan
        } catch {
            Write-Warning "Erro INSERT lote $i : $_"
        }
    }
}

function To-DataISO($str) {
    if ($str -match '(\d{2})/(\d{2})/(\d{4})') { return "$($matches[3])-$($matches[2])-$($matches[1])" }
    if ($str -match '(\d{4}-\d{2}-\d{2})')      { return $matches[1] }
    return $null
}

function Parse-DataHora($str) {
    if (-not $str) { return $null }
    try {
        if ($str -match '(\d{2})/(\d{2})/(\d{4}) (\d{2}):(\d{2}):(\d{2})') {
            return [datetime]::new([int]$matches[3],[int]$matches[2],[int]$matches[1],[int]$matches[4],[int]$matches[5],[int]$matches[6])
        }
    } catch { return $null }
    return $null
}

# -- Janela --------------------------------------------------------
$hoje       = Get-Date
$dataInicio = $hoje.AddDays(-$JANELA_DIAS).ToString("yyyy-MM-dd")
$dataFim    = $hoje.ToString("yyyy-MM-dd")

Write-Host "Janela: $dataInicio ate $dataFim" -ForegroundColor Yellow

# Lista de dias da janela
$dias = @()
$d = $hoje.AddDays(-$JANELA_DIAS)
while ($d -le $hoje) {
    $dias += $d
    $d = $d.AddDays(1)
}

# -- Main ----------------------------------------------------------
Import-Module Az.Storage -ErrorAction Stop
$ctx    = New-AzStorageContext -ConnectionString $CONN_STRING
$tmpDir = "C:\sync_praxio\tmp_viagens"
New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
$agora  = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")

foreach ($prefixo in $GARAGEM_MAP.Keys) {
    $gid = $GARAGEM_MAP[$prefixo].gid
    $cod = $GARAGEM_MAP[$prefixo].cod

    Write-Host ""
    Write-Host "=== $prefixo ($cod) ===" -ForegroundColor Yellow

    # 1. Apaga TODOS os registros desta garagem no Supabase antes de reinserir
    Write-Host "  Limpando todos os registros de $cod..."
    $delUri = "$SUPABASE_URL/rest/v1/viagens_resumo?garagem_cod=eq.$cod"
    $delHdr = @{ "apikey" = $SUPABASE_KEY; "Authorization" = "Bearer $SUPABASE_KEY"; "Prefer" = "return=minimal" }
    try { Invoke-RestMethod -Method DELETE -Uri $delUri -Headers $delHdr | Out-Null } catch { Write-Warning "Delete: $_" }

    # 2. Baixa e agrega um arquivo por dia
    $registros = [System.Collections.Generic.List[object]]::new()

    foreach ($dia in $dias) {
        $sufixo = $dia.ToString("dd_MM_yyyy")
        $blob   = "$BLOB_PREFIX/$prefixo $sufixo.json"
        $tmp    = "$tmpDir\${prefixo}_${sufixo}.json"

        Write-Host "  Baixando $blob..." -NoNewline
        try {
            Get-AzStorageBlobContent -Container $CONTAINER -Blob $blob -Destination $tmp -Context $ctx -Force -ErrorAction Stop | Out-Null
            Write-Host " OK" -ForegroundColor Green
        } catch {
            Write-Host " nao encontrado" -ForegroundColor DarkGray
            continue
        }

        $json    = Get-Content $tmp -Raw -Encoding UTF8 | ConvertFrom-Json
        $viagens = $json.viagens

        if (-not $viagens -or $viagens.Count -eq 0) {
            Write-Host "  (sem viagens)"
            continue
        }
        Write-Host "  $($viagens.Count) viagens"

        # Agrega por (linha, veiculo, motorista) dentro do dia
        $dataISO = $dia.ToString("yyyy-MM-dd")

        $grupos = $viagens | Group-Object {
            $mv = if ($_.motorista) { $_.motorista } else { "SEM_MOTORISTA" }
            $_.linha + "~" + $_.veiculo + "~" + $mv
        }

        foreach ($g in $grupos) {
            $p = $g.Name -split "~"
            if (-not $p[0]) { continue }

            $realizadas = 0; $pontuais = 0; $adiantadas = 0; $atrasadas = 0
            foreach ($trip in $g.Group) {
                if ($null -eq $trip.inicioRealizado) { continue }
                $realizadas++
                $prog = Parse-DataHora $trip.inicioProgramado
                $real = Parse-DataHora $trip.inicioRealizado
                if (-not $prog -or -not $real) { continue }
                $diff = ($real - $prog).TotalMinutes
                if     ($diff -lt -10) { $adiantadas++ }
                elseif ($diff -le  10) { $pontuais++   }
                else                   { $atrasadas++  }
            }

            $registros.Add([PSCustomObject]@{
                garagem_id           = $gid
                garagem_cod          = $cod
                data                 = $dataISO
                linha                = $p[0]
                veiculo              = $p[1]
                motorista_cod        = $p[2]
                viagens_programadas  = $g.Count
                viagens_realizadas   = $realizadas
                viagens_pontuais     = $pontuais
                viagens_adiantadas   = $adiantadas
                viagens_atrasadas    = $atrasadas
                updated_at           = $agora
            })
        }
    }

    # 3. Insere dados frescos
    Write-Host "  Inserindo $($registros.Count) registros no Supabase..."
    Supabase-Insert "viagens_resumo" $registros
    Write-Host "  $prefixo concluido!" -ForegroundColor Green
}

Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host ""
Write-Host "Sync concluido! Janela: $dataInicio ate $dataFim" -ForegroundColor Green
