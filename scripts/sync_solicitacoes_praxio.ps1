# Sincroniza requisicoes_compra a partir da requisicao oficial do PRAXIO/Oracle --
# em vez do PCM digitar a peca manualmente no app, o item nasce direto da
# requisicao formal (PI_MAN + EST_REQUISICAO + EST_ITENSREQUISICAO) assim que
# o PCM formaliza ela no sistema oficial. Cobre QUALQUER OS dentro da janela
# (aberta ou ja fechada) -- o Almoxarifado ve as abertas na tela de sempre
# ("Solicitacoes de OS"), e o PCM confere aberta+fechada na aba "Peças PRAXIO"
# (Ferramentas > Painel PCM).
#
# Roda periodicamente (Task Scheduler, poucos minutos) a partir de 2026-07-06.
#
# IMPORTANTE -- diferente dos outros syncs deste projeto (Km/L, viagens): NAO
# pode ser delete+insert. Cada linha de requisicoes_compra carrega estado de
# workflow local (separado/pedido_compra/comprado, quem separou, quando
# chegou) que seria perdido se a linha fosse recriada. Por isso: so faz INSERT
# do que ainda nao existe (checa (os_numero, cod_sap) antes), nunca
# update/delete em linha ja criada.
#
# RODAR NO SERVIDOR. Senha vem de $env:JTP_ORACLE_PWD.

param(
    [int]$JanelaDias = 3
)

$DSN = "GLOBUSSERVER"
$UID = if ($env:JTP_ORACLE_UID) { $env:JTP_ORACLE_UID } else { "CONSULTA868" }
$PWD_ORACLE = if ($env:JTP_ORACLE_PWD) { $env:JTP_ORACLE_PWD } else { "COLE_AQUI" }

$SUPABASE_URL = "https://yxwxcxdegkvjvwchemsm.supabase.co"
$SUPABASE_KEY = "sb_publishable_SvC1D0cMk94sZ_9kYv41QQ_RJVrSuUV"
$GARAGEM_ID_PVH = "aaaaaaaa-0001-0000-0000-000000000001"
$FILIAL_PVH = "PORTO VELHO"

$hdr = @{ "apikey" = $SUPABASE_KEY; "Authorization" = "Bearer $SUPABASE_KEY" }
$hdrWrite = $hdr + @{ "Content-Type" = "application/json"; "Prefer" = "return=minimal" }

Write-Host "=== Sync Solicitacoes PRAXIO -- $(Get-Date) ===" -ForegroundColor Yellow

function Formata-Prefixo($raw) {
    $s = "$raw".Trim()
    if ($s.Length -ge 5 -and $s -match '^\d+$') {
        $last5 = $s.Substring($s.Length - 5)
        return $last5.Substring(0,2) + "." + $last5.Substring(2)
    }
    return $s
}

# -- 1) Consulta Oracle: itens de requisicao das OS abertas ------------------
if ($PWD_ORACLE -eq "COLE_AQUI") {
    Write-Error "JTP_ORACLE_PWD nao esta definida nesta sessao (senha caiu no valor padrao 'COLE_AQUI'). Rode: `$env:JTP_ORACLE_PWD = 'a senha real' -- antes de chamar o script."
    exit 1
}

Add-Type -AssemblyName System.Data
$conn = New-Object System.Data.Odbc.OdbcConnection
$conn.ConnectionString = "DSN=$DSN;UID=$UID;PWD=$PWD_ORACLE"
try {
    $conn.Open()
} catch {
    Write-Error "Falha ao conectar na Oracle (DSN=$DSN, UID=$UID): $($_.Exception.Message)"
    exit 1
}

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

$dataMinOracle = (Get-Date).AddDays(-$JanelaDias).ToString("yyyy-MM-dd")
Write-Host "Consultando Oracle (todas as OS, abertas e fechadas, filial $FILIAL_PVH, desde $dataMinOracle)..." -ForegroundColor Cyan

# IMPORTANTE (2026-07-06): CODIGOMATINT e codigo INTERNO da Oracle, nao e o
# mesmo que o cod_sap (8 digitos, tipo 30016636) usado no app. O campo que
# corresponde ao cod_sap e CODIGOINTERNOMATERIAL -- mesma correcao ja aplicada
# em sync_divergencias_pecas.ps1. O JOIN interno continua por CODIGOMATINT
# (isso esta certo, e a chave real entre EST_ITENSREQUISICAO e EST_CADMATERIAL)
# -- so trocamos qual coluna exportamos pra comparar/gravar como cod_sap.
#
# MUDANCA (2026-07-06, tarde): antes so trazia OS aberta (usando o mesmo
# filtro de renderManutencao). Daniel pediu pra trazer TODAS as OS da janela,
# abertas ou fechadas -- o uso real e o PCM validar a peca usada em qualquer
# OS, nao so rastrear pendencia de OS ainda aberta. Por isso o filtro de
# CONDICAO_OS foi removido daqui; so resta a janela de data + filial.
$sql = @"
SELECT p.NUMERO_OS, p.PREFIXO_VEIC, c.CODIGOINTERNOMATERIAL AS COD_SAP, c.DESCRICAOMAT,
       SUM(it.QTDEITREQ) AS QTD_ORACLE
FROM (
    SELECT CODINTOS, MIN(NUMERO_OS) AS NUMERO_OS, MIN(PREFIXO_VEIC) AS PREFIXO_VEIC
    FROM GLOBUS868.PI_MAN
    WHERE DATA_OS >= TO_DATE('$dataMinOracle','YYYY-MM-DD')
      AND FILIAL LIKE '%$FILIAL_PVH%'
    GROUP BY CODINTOS
) p
JOIN GLOBUS868.EST_REQUISICAO r ON r.CODINTOS = p.CODINTOS
JOIN GLOBUS868.EST_ITENSREQUISICAO it ON it.NUMERORQ = r.NUMERORQ
JOIN GLOBUS868.EST_CADMATERIAL c ON c.CODIGOMATINT = it.CODIGOMATINT
GROUP BY p.NUMERO_OS, p.PREFIXO_VEIC, c.CODIGOINTERNOMATERIAL, c.DESCRICAOMAT
"@
$oracleRows = Roda-Query $sql 180
$conn.Close()
Write-Host "$($oracleRows.Count) itens de requisicao encontrados na Oracle." -ForegroundColor Green

if ($oracleRows.Count -eq 0) {
    Write-Host "Nada a sincronizar." -ForegroundColor Yellow
    return
}

# -- 2) Monta os candidatos --------------------------------------------------
# IMPORTANTE (2026-07-13): antes o dedup era feito aqui no PowerShell (buscar
# os_numero+cod_sap ja existentes e comparar em memoria). Isso falhou de forma
# silenciosa -- rodando a cada 30min, criou 1110 linhas duplicadas num unico
# dia (ver scripts/dedupe_e_travar_requisicoes_praxio.sql pra limpeza). Causa
# exata nao confirmada (URL longa demais com muitos os_numero, tipo Decimal do
# ODBC formatando diferente do texto salvo, etc) -- em vez de caçar a causa,
# o dedup agora e garantido pelo PROPRIO BANCO: indice unico parcial em
# requisicoes_compra(os_numero, cod_sap) WHERE status <> 'cancelado', e o
# insert abaixo usa upsert com "ignore-duplicates" (equivalente a ON CONFLICT
# DO NOTHING). Mesmo que esse script rode 2x, ou 100x, o Postgres nunca deixa
# duplicar -- so roda a migracao SQL uma vez antes de usar esta versao.
$hoje = (Get-Date).ToString("yyyy-MM-dd")
$agora = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
$candidatos = [System.Collections.Generic.List[object]]::new()
foreach ($o in $oracleRows) {
    if (-not $o.COD_SAP) { continue }  # sem codigo de material, nao da pra rastrear
    $candidatos.Add([PSCustomObject]@{
        garagem_id  = $GARAGEM_ID_PVH
        os_numero   = "$($o.NUMERO_OS)"
        prefixo     = Formata-Prefixo $o.PREFIXO_VEIC
        cod_sap     = "$($o.COD_SAP)"
        peca        = $o.DESCRICAOMAT
        quantidade  = $o.QTD_ORACLE
        data        = $hoje
        status      = "solicitado_pcm"
        criado_por  = "Sync PRAXIO"
        criado_em   = $agora
    })
}
$novos = $candidatos
Write-Host ""
Write-Host "$($candidatos.Count) candidato(s) da Oracle (o banco decide quais ja existem)." -ForegroundColor Cyan

# Invoke-RestMethod no Windows PowerShell 5.1 nao manda o -Body (string) como
# UTF-8 de verdade quando tem acento/cedilha -- o Supabase recebe bytes
# corrompidos e responde "empty or invalid json" (PGRST102). Por isso convertemos
# o JSON pra bytes UTF-8 explicitamente antes de mandar.
function Post-SupabaseJson($uri, $headers, $bodyObj) {
    $json = $bodyObj | ConvertTo-Json -Depth 3
    if ($bodyObj.Count -eq 1 -or $bodyObj -isnot [array]) { $json = "[$json]" }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    Invoke-RestMethod -Method POST -Uri $uri -Headers $headers -Body $bytes -ContentType "application/json; charset=utf-8"
}

if ($novos.Count -gt 0) {
    $novos | Format-Table os_numero, prefixo, cod_sap, quantidade, peca -AutoSize
    # on_conflict + Prefer: resolution=ignore-duplicates == ON CONFLICT DO
    # NOTHING no Postgres. Exige o indice unico parcial criado por
    # scripts/dedupe_e_travar_requisicoes_praxio.sql. return=representation
    # devolve so as linhas que realmente foram inseridas (as que ja existiam
    # voltam vazias), entao o log mostra o numero real de itens novos.
    $uriUpsert = "$SUPABASE_URL/rest/v1/requisicoes_compra?on_conflict=os_numero,cod_sap"
    $hdrUpsert = $hdr + @{ "Content-Type" = "application/json; charset=utf-8"; "Prefer" = "resolution=ignore-duplicates,return=representation" }
    try {
        $inseridos = @(Post-SupabaseJson $uriUpsert $hdrUpsert $novos)
        Write-Host "$($inseridos.Count) item(ns) realmente novo(s) inserido(s) em requisicoes_compra (o resto ja existia -- o banco ignorou)." -ForegroundColor Green
    } catch {
        Write-Warning "Erro inserindo: $($_.Exception.Message)"
        $respBody = $null
        try {
            if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
                $respBody = $_.ErrorDetails.Message
            } elseif ($_.Exception.Response) {
                $stream = $_.Exception.Response.GetResponseStream()
                $stream.Position = 0
                $reader = New-Object System.IO.StreamReader($stream)
                $respBody = $reader.ReadToEnd()
            }
        } catch {}
        if ($respBody) { Write-Warning "Detalhe do Supabase: $respBody" }

        Write-Host "Tentando inserir item a item pra achar o(s) registro(s) com problema..." -ForegroundColor Yellow
        foreach ($n in $novos) {
            try {
                Post-SupabaseJson $uriUpsert $hdrUpsert @($n) | Out-Null
                Write-Host "  OK  os=$($n.os_numero) cod_sap=$($n.cod_sap)" -ForegroundColor Green
            } catch {
                $detalhe = $null
                try {
                    if ($_.ErrorDetails -and $_.ErrorDetails.Message) { $detalhe = $_.ErrorDetails.Message }
                    elseif ($_.Exception.Response) {
                        $s = $_.Exception.Response.GetResponseStream(); $s.Position = 0
                        $detalhe = (New-Object System.IO.StreamReader($s)).ReadToEnd()
                    }
                } catch {}
                Write-Host "  FALHOU os=$($n.os_numero) cod_sap=$($n.cod_sap) peca=$($n.peca) -- $detalhe" -ForegroundColor Red
            }
        }
    }
}

Write-Host ""
Write-Host "Concluido em $(Get-Date)." -ForegroundColor Green
