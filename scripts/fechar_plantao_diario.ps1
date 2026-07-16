# Fechamento automatico diario do modulo Plantao Inteligente (dobras, absenteismo,
# S.O.S., trocas) -- roda sozinho via Windows Task Scheduler as 02:00, sem
# depender de ninguem abrir o app. Consolida o dia operacional ANTERIOR
# (ontem, na timezone de cada garagem) em fechamento_plantao, gera um PDF
# igual ao estilo dos outros relatorios do sistema, e manda o resumo (texto +
# arquivo) pro WhatsApp.
#
# Mesmo padrao de conexao dos syncs do PRAXIO (scripts/sync_solicitacoes_praxio.ps1):
# fala REST direto com o Supabase via Invoke-RestMethod, sem SDK.
#
# RODAR NO SERVIDOR. Nao precisa de credencial Oracle -- so le/grava Supabase.
#
# IMPORTANTE -- usa a service_role key do Supabase, nao a chave publica (anon).
# As tabelas plantao_* tem RLS "TO authenticated" -- uma chamada sem sessao de
# usuario logado (like este script) e tratada como anonima e o RLS filtra tudo
# em silencio (zero linhas, sem erro). service_role ignora RLS, e por isso NAO
# pode ficar hardcoded aqui nem no repo -- ela concede acesso total ao banco.
# Pegue em Supabase > Project Settings > API > service_role secret, e rode:
#   $env:JTP_SUPABASE_SERVICE_KEY = "a chave real"
# antes de chamar este script (mesmo padrao do $env:JTP_ORACLE_PWD nos syncs do PRAXIO).

$ErrorActionPreference = "Stop"

$SUPABASE_URL = "https://yxwxcxdegkvjvwchemsm.supabase.co"
$SUPABASE_KEY = if ($env:JTP_SUPABASE_SERVICE_KEY) { $env:JTP_SUPABASE_SERVICE_KEY } else { "COLE_AQUI" }
$WPP_GROUP    = "120363427489152994@g.us"
$WPP_URL      = "https://evolution-api-production-8d56.up.railway.app/message"
$WPP_APIKEY   = "4289AC11F437-43AD-96D7-9F27C2735696"
$WPP_INSTANCE = "jtp-garagem"

if ($SUPABASE_KEY -eq "COLE_AQUI") {
  Write-Error "JTP_SUPABASE_SERVICE_KEY nao esta definida nesta sessao. Rode: `$env:JTP_SUPABASE_SERVICE_KEY = 'a chave real' -- antes de chamar o script. Pegue em Supabase > Project Settings > API > service_role secret."
  exit 1
}

$EDGE_PATHS = @(
  "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
  "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
)
$EDGE = $EDGE_PATHS | Where-Object { Test-Path $_ } | Select-Object -First 1

$LOG_PATH = Join-Path $PSScriptRoot "fechar_plantao_diario.log"
function Log($msg) {
  $linha = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $msg"
  Write-Host $linha
  Add-Content -Path $LOG_PATH -Value $linha -Encoding UTF8
}

$hdr = @{ "apikey" = $SUPABASE_KEY; "Authorization" = "Bearer $SUPABASE_KEY" }
$hdrUpsert = $hdr + @{ "Content-Type" = "application/json; charset=utf-8"; "Prefer" = "resolution=merge-duplicates,return=representation" }

function Get-SupabaseJson($uri) {
  return Invoke-RestMethod -Method GET -Uri $uri -Headers $hdr
}
function Upsert-SupabaseJson($uri, $bodyObj) {
  $json = $bodyObj | ConvertTo-Json -Depth 8
  if ($bodyObj -isnot [array]) { $json = "[$json]" }
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
  return Invoke-RestMethod -Method POST -Uri $uri -Headers $hdrUpsert -Body $bytes -ContentType "application/json; charset=utf-8"
}

function Get-TzId($garagem) {
  $txt = ("$($garagem.nome) $($garagem.cidade) $($garagem.sigla)").ToLower()
  if ($txt -match 'braganca') { return 'E. South America Standard Time' }
  return 'SA Western Standard Time'
}
function Get-DataOntem($tzId) {
  $tz = [System.TimeZoneInfo]::FindSystemTimeZoneById($tzId)
  $nowLocal = [System.TimeZoneInfo]::ConvertTimeFromUtc([System.DateTime]::UtcNow, $tz)
  return $nowLocal.Date.AddDays(-1).ToString('yyyy-MM-dd')
}

function Esc($s) {
  if ($null -eq $s) { return "" }
  return [System.Web.HttpUtility]::HtmlEncode("$s")
}

Log "=== Fechamento diario do Plantao ==="

Add-Type -AssemblyName System.Web

$garagens = Get-SupabaseJson "$SUPABASE_URL/rest/v1/garagens?select=id,nome,cidade,sigla"
Log "$($garagens.Count) garagem(ns) encontrada(s)."

foreach ($g in $garagens) {
  $gid = $g.id
  $tzId = Get-TzId $g
  $dataOntem = Get-DataOntem $tzId
  Log "-- $($g.nome) ($gid) -- fechando $dataOntem (tz=$tzId)"

  try {
    $uriDobras = "$SUPABASE_URL/rest/v1/plantao_dobras?garagem_id=eq.$gid&data=eq.$dataOntem&select=*"
    $uriAbsenteismo = "$SUPABASE_URL/rest/v1/plantao_absenteismo?garagem_id=eq.$gid&data=eq.$dataOntem&select=*"
    $uriSos = "$SUPABASE_URL/rest/v1/plantao_sos?garagem_id=eq.$gid&data=eq.$dataOntem&select=*"
    $uriTrocas = "$SUPABASE_URL/rest/v1/plantao_trocas?garagem_id=eq.$gid&data=eq.$dataOntem&select=*"
    Log "DEBUG uri dobras: $uriDobras"
    $dobras       = Get-SupabaseJson $uriDobras
    Log "DEBUG dobras retornou $($dobras.Count) linha(s)"
    $absenteismo  = Get-SupabaseJson $uriAbsenteismo
    Log "DEBUG absenteismo retornou $($absenteismo.Count) linha(s)"
    $sos          = Get-SupabaseJson $uriSos
    Log "DEBUG sos retornou $($sos.Count) linha(s)"
    $trocas       = Get-SupabaseJson $uriTrocas
    Log "DEBUG trocas retornou $($trocas.Count) linha(s)"
  } catch {
    Log "ERRO ao buscar lancamentos: $($_.Exception.Message)"
    continue
  }

  $sosNaoResolvidos = @($sos | Where-Object { $_.status -eq 'aberto' })

  if ($dobras.Count -eq 0 -and $absenteismo.Count -eq 0 -and $sos.Count -eq 0 -and $trocas.Count -eq 0) {
    Log "Nada lancado em $dataOntem -- sem fechamento a gerar pra essa garagem."
    continue
  }

  # -- 1) Upsert do fechamento consolidado ------------------------------------
  $detalhes = @{ dobras = $dobras; absenteismo = $absenteismo; sos = $sos; trocas = $trocas }
  $fechamento = @{
    garagem_id                = $gid
    data                      = $dataOntem
    total_dobras              = $dobras.Count
    total_absenteismo         = $absenteismo.Count
    total_sos                 = $sos.Count
    total_sos_nao_resolvidos  = $sosNaoResolvidos.Count
    total_trocas              = $trocas.Count
    detalhes                  = $detalhes
    gerado_automaticamente    = $true
    fechado_em                = (Get-Date).ToUniversalTime().ToString("o")
  }
  try {
    Upsert-SupabaseJson "$SUPABASE_URL/rest/v1/fechamento_plantao?on_conflict=garagem_id,data" $fechamento | Out-Null
    Log "Fechamento gravado: $($dobras.Count) dobra(s), $($absenteismo.Count) falta(s), $($sos.Count) SOS ($($sosNaoResolvidos.Count) nao resolvido(s)), $($trocas.Count) troca(s)."
  } catch {
    Log "ERRO ao gravar fechamento_plantao: $($_.Exception.Message)"
    continue
  }

  # -- 2) Montar o HTML do relatorio -------------------------------------------
  $dataFmt = ([datetime]$dataOntem).ToString("dd/MM/yyyy")
  $B = "border:1px solid #333;"
  $BH = "border:1px solid #333;background:#555;color:#fff;font-weight:900;"

  function Tabela($titulo, $linhas, $colunas) {
    $cab = ($colunas | ForEach-Object { "<th style=`"$BH padding:4px`">$(Esc $_)</th>" }) -join ""
    $corpo = if ($linhas.Count -eq 0) {
      "<tr><td colspan=`"$($colunas.Count)`" style=`"$B padding:6px;text-align:center`">Nenhum lancamento</td></tr>"
    } else { $linhas -join "" }
    return "<div style=`"font-weight:900;background:#555;color:#fff;border:1.5px solid #111;padding:3px 8px;margin:10px 0 2px`">$titulo</div><table style=`"border-collapse:collapse;width:100%`"><thead><tr>$cab</tr></thead><tbody>$corpo</tbody></table>"
  }

  $linhasDobras = $dobras | ForEach-Object {
    "<tr><td style=`"$B padding:4px`">$(Esc $_.motorista)</td><td style=`"$B padding:4px`">$(Esc $_.prefixo)</td><td style=`"$B padding:4px`">$(Esc $_.linha)</td><td style=`"$B padding:4px`">$(Esc $_.motivo)</td></tr>"
  }
  $linhasAbsenteismo = $absenteismo | ForEach-Object {
    "<tr><td style=`"$B padding:4px`">$(Esc $_.motorista)</td><td style=`"$B padding:4px`">$(Esc $_.linha)</td><td style=`"$B padding:4px`">$(Esc $_.motivo)</td><td style=`"$B padding:4px`">$(Esc $_.cobertura)</td></tr>"
  }
  $linhasSos = $sos | ForEach-Object {
    $statusTxt = if ($_.status -eq 'aberto') { 'ABERTO' } else { 'ENCERRADO' }
    "<tr><td style=`"$B padding:4px`">$(Esc $_.prefixo)</td><td style=`"$B padding:4px`">$(Esc $_.linha)</td><td style=`"$B padding:4px`">$(Esc $_.problema)</td><td style=`"$B padding:4px`">$(Esc $_.decisao)</td><td style=`"$B padding:4px;font-weight:700`">$statusTxt</td></tr>"
  }
  $linhasTrocas = $trocas | ForEach-Object {
    "<tr><td style=`"$B padding:4px`">$(Esc $_.tipo)</td><td style=`"$B padding:4px`">$(Esc $_.prefixo)</td><td style=`"$B padding:4px`">$(Esc $_.original)</td><td style=`"$B padding:4px`">$(Esc $_.substituto)</td><td style=`"$B padding:4px`">$(Esc $_.motivo)</td></tr>"
  }

  $html = @"
<!DOCTYPE html><html><head><meta charset="UTF-8"><style>
body{font-family:Arial,sans-serif;font-size:11px;color:#000;margin:10px}
table{border-collapse:collapse;width:100%}
</style></head><body>
<div style="text-align:center;border:2.5px solid #000;padding:6px;margin-bottom:6px;background:#fff">
<div style="font-size:14px;font-weight:900;letter-spacing:1px">GRUPO JTP | FECHAMENTO AUTOMATICO DO PLANTAO</div>
</div>
<table style="margin-bottom:4px"><tr>
<td style="$B padding:4px 8px"><strong>Data:</strong> $dataFmt</td>
<td style="$B padding:4px 8px"><strong>Garagem:</strong> $(Esc $g.nome)</td>
<td style="$B padding:4px 8px"><strong>Gerado em:</strong> $(Get-Date -Format 'dd/MM/yyyy HH:mm')</td>
</tr></table>
$(Tabela "DOBRAS ($($dobras.Count))" $linhasDobras @("Motorista","Prefixo","Linha","Motivo"))
$(Tabela "ABSENTEISMO ($($absenteismo.Count))" $linhasAbsenteismo @("Motorista","Linha","Motivo","Cobertura"))
$(Tabela "S.O.S. ($($sos.Count)) -- $($sosNaoResolvidos.Count) nao resolvido(s)" $linhasSos @("Prefixo","Linha","Problema","Decisao","Status"))
$(Tabela "TROCAS ($($trocas.Count))" $linhasTrocas @("Tipo","Prefixo","Original","Substituto","Motivo"))
</body></html>
"@

  $tmpDir = [System.IO.Path]::GetTempPath()
  $htmlPath = Join-Path $tmpDir "fechamento_plantao_$($gid)_$($dataOntem -replace '-','').html"
  $pdfPath  = Join-Path $tmpDir "JTP_Fechamento_Plantao_$($dataOntem -replace '-','')_$($g.nome -replace '\s','_').pdf"
  Set-Content -Path $htmlPath -Value $html -Encoding UTF8

  # -- 3) Gerar o PDF via Edge headless -----------------------------------------
  $pdfOk = $false
  if ($EDGE) {
    try {
      $fileUri = "file:///$($htmlPath -replace '\\','/')"
      $edgeArgs = @('--headless','--disable-gpu',"--print-to-pdf=$pdfPath",'--no-margins',$fileUri)
      $proc = Start-Process -FilePath $EDGE -ArgumentList $edgeArgs -Wait -PassThru -WindowStyle Hidden
      $pdfOk = Test-Path $pdfPath
      Log $(if ($pdfOk) { "PDF gerado: $pdfPath" } else { "PDF nao foi gerado (Edge saiu com codigo $($proc.ExitCode))" })
    } catch {
      Log "ERRO ao gerar PDF: $($_.Exception.Message)"
    }
  } else {
    Log "Edge nao encontrado nos caminhos padrao -- PDF nao gerado, seguindo so com o resumo em texto."
  }

  # -- 4) Resumo em texto pro WhatsApp -------------------------------------------
  $msg = "*FECHAMENTO AUTOMATICO -- PLANTAO*`n" +
         "$(Esc $g.nome) . $dataFmt`n`n" +
         "Dobras: $($dobras.Count)`n" +
         "Absenteismo: $($absenteismo.Count)`n" +
         "S.O.S.: $($sos.Count) ($($sosNaoResolvidos.Count) nao resolvido(s))`n" +
         "Trocas: $($trocas.Count)`n`n" +
         "_Gerado automaticamente as 02:00_"
  try {
    $bodyTxt = @{ number = $WPP_GROUP; options = @{ delay = 0 }; textMessage = @{ text = $msg } } | ConvertTo-Json -Depth 5
    Invoke-RestMethod -Method POST -Uri "$WPP_URL/sendText/$WPP_INSTANCE" -Headers @{ "Content-Type" = "application/json"; "apikey" = $WPP_APIKEY } -Body ([System.Text.Encoding]::UTF8.GetBytes($bodyTxt)) -ContentType "application/json; charset=utf-8" | Out-Null
    Log "Resumo em texto enviado pro WhatsApp."
  } catch {
    Log "ERRO ao enviar texto pro WhatsApp: $($_.Exception.Message)"
    try {
      $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
      Log "DEBUG resposta do servidor: $($reader.ReadToEnd())"
    } catch {}
  }

  # -- 5) PDF pro WhatsApp -- PONTO NAO TESTADO, ver plano/README ----------------
  if ($pdfOk) {
    try {
      $base64 = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($pdfPath))
      $bodyMedia = @{
        number    = $WPP_GROUP
        mediatype = "document"
        mimetype  = "application/pdf"
        fileName  = [System.IO.Path]::GetFileName($pdfPath)
        caption   = "Fechamento do Plantao -- $(Esc $g.nome) $dataFmt"
        media     = $base64
      } | ConvertTo-Json -Depth 5
      Invoke-RestMethod -Method POST -Uri "$WPP_URL/sendMedia/$WPP_INSTANCE" -Headers @{ "Content-Type" = "application/json"; "apikey" = $WPP_APIKEY } -Body ([System.Text.Encoding]::UTF8.GetBytes($bodyMedia)) -ContentType "application/json; charset=utf-8" | Out-Null
      Log "PDF enviado pro WhatsApp."
    } catch {
      Log "AVISO -- envio do PDF por WhatsApp falhou (endpoint nao testado ainda neste projeto): $($_.Exception.Message)"
      try {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        Log "DEBUG resposta do servidor: $($reader.ReadToEnd())"
      } catch {}
    }
  }
}

Log "=== Fim do fechamento ==="
