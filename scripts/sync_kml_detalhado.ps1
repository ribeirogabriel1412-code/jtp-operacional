# Sync Oracle (VW_LANCAMENTOABASTECIMENTO) -> Supabase (instrutor_kml_detalhado)
# Janela fixa: ultimos 60 dias (sempre sobrescreve por garagem)
# Local no servidor: C:\sync_praxio\sync_kml_detalhado.ps1
# Task Scheduler: rodar 1x ao dia
#
# Calculo validado em 2026-07-05 contra painel oficial (Porto Velho/junho):
# varios veiculos bateram exato ate a casa decimal. Litro derivado de
# KM_PERCORRIDO/KM_POR_L (nao usar QUANTIDADE_COMBUSTIVEL, escala inconsistente).
#
# Credenciais vem de variaveis de ambiente (nunca colar aqui):
#   $env:JTP_ORACLE_UID / $env:JTP_ORACLE_PWD

$DSN = "GLOBUSSERVER"
$UID = if ($env:JTP_ORACLE_UID) { $env:JTP_ORACLE_UID } else { "CONSULTA868" }
$PWD_ORACLE = if ($env:JTP_ORACLE_PWD) { $env:JTP_ORACLE_PWD } else { "COLE_AQUI" }

$SUPABASE_URL = "https://yxwxcxdegkvjvwchemsm.supabase.co"
$SUPABASE_KEY = "sb_publishable_SvC1D0cMk94sZ_9kYv41QQ_RJVrSuUV"
$BATCH        = 400
$JANELA_DIAS  = 60

# Teto de plausibilidade para KM_POR_L (2026-07-05): achados registros isolados
# (ex: 918km/114L=8.04, 828km/98L=8.44) muito acima do padrao real do veiculo
# (~2.0-2.5, confirmado contra painel oficial). Provavel gap de hodometro entre
# abastecimentos (varios dias sem abastecer, litros nao acompanha a distancia
# acumulada). Descartar esses registros do agregado -- mesmo espirito do
# MINIMO_ABAST em motor_kml.ps1 (nao usar dado que sabidamente distorce a media).
$MAX_KML_PLAUSIVEL = 5.0

$TABELA_ORACLE = "GLOBUS868.VW_LANCAMENTOABASTECIMENTO"

# Prefixo de frota -> garagem no Supabase (mesma logica ja usada no motor_kml.ps1:
# Porto Velho = 02.xxx, Braganca = 03.xxx). So Porto Velho ativo por enquanto --
# Braganca ainda nao existe na tabela garagens do Supabase (ver azure_viagens_sync.md).
$GARAGEM_MAP = @(
    @{ prefixoFrota = "02"; gid = "aaaaaaaa-0001-0000-0000-000000000001"; cod = "JTP01" }
    # @{ prefixoFrota = "03"; gid = "UUID_BRAGANCA_AQUI"; cod = "JTP02" }
)

function Formata-Prefixo($raw) {
    $s = "$raw".Trim()
    if ($s.Length -ge 5 -and $s -match '^\d+$') {
        $last5 = $s.Substring($s.Length - 5)
        return $last5.Substring(0,2) + "." + $last5.Substring(2)
    }
    return $s
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

$hoje       = Get-Date
$dataInicio = $hoje.AddDays(-$JANELA_DIAS).ToString("yyyy-MM-dd")
$dataFim    = $hoje.ToString("yyyy-MM-dd")
Write-Host "Sync Km/L Detalhado -- Janela: $dataInicio ate $dataFim" -ForegroundColor Yellow

Add-Type -AssemblyName System.Data
$conn = New-Object System.Data.Odbc.OdbcConnection
$conn.ConnectionString = "DSN=$DSN;UID=$UID;PWD=$PWD_ORACLE"
$conn.Open()

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
        # Garante que o reader fecha mesmo se der excecao no meio da leitura --
        # sem isso, uma linha problematica (ex: divisao por zero na view) deixa a
        # conexao num estado ruim e derruba os dias seguintes em cascata.
        if (-not $reader.IsClosed) { $reader.Close() }
    }
}

Write-Host "Consultando Oracle (dia a dia -- a view tem calculo interno que da erro" -ForegroundColor Cyan
Write-Host "de divisao por zero nalguns registros; isolar por dia evita derrubar o sync todo)..." -ForegroundColor Cyan
$linhas = [System.Collections.Generic.List[object]]::new()
$diasComErro = 0
$dia = [datetime]::ParseExact($dataInicio, "yyyy-MM-dd", $null)
$fimLoop = [datetime]::ParseExact($dataFim, "yyyy-MM-dd", $null)
while ($dia -le $fimLoop) {
    $diaStr = $dia.ToString("yyyy-MM-dd")
    $sqlDia = @"
SELECT PREFIXO, PLACA, DATA_ABASTECIMENTO, KM_PERCORRIDO, KM_POR_L,
       CODIGO_MOTORISTA, NOME_MOTORISTA, CODIGO_LINHA, NOME_LINHA, HODOMETRO_FINAL
FROM $TABELA_ORACLE
WHERE DATA_ABASTECIMENTO >= TO_DATE('$diaStr','YYYY-MM-DD')
  AND DATA_ABASTECIMENTO <  TO_DATE('$diaStr','YYYY-MM-DD') + 1
  AND PLACA IS NOT NULL
  AND KM_PERCORRIDO > 0
  AND KM_POR_L IS NOT NULL
"@
    # IMPORTANTE (2026-07-05): "KM_POR_L > 0" causava ORA-01476 (divisor igual a
    # zero) num punhado de linhas por dia (a view calcula isso internamente e o
    # ">" forcava avaliar antes de filtrar). Trocado por "IS NOT NULL", que evita
    # o erro sem descartar o dia inteiro -- confirmado testando os 3 dias que
    # falhavam antes, agora ok. O ">0" fica so como checagem no PowerShell depois.
    try {
        $doDia = @(Roda-Query $sqlDia 60 | Where-Object { $_.KM_POR_L -gt 0 -and $_.KM_POR_L -le $MAX_KML_PLAUSIVEL })
        foreach ($r in $doDia) { $linhas.Add($r) }
    } catch {
        $diasComErro++
        Write-Warning "Dia $diaStr falhou (pulado): $($_.Exception.Message)"
    }
    $dia = $dia.AddDays(1)
}
Write-Host "$($linhas.Count) abastecimentos validos encontrados ($diasComErro dias com erro, pulados)." -ForegroundColor Green
$conn.Close()

if ($linhas.Count -eq 0) {
    Write-Host "Nenhum dado encontrado no periodo." -ForegroundColor Red
    return
}

# Litro implicito derivado do KM_POR_L ja validado pela view (nao usar
# QUANTIDADE_COMBUSTIVEL -- escala inconsistente entre materiais/registros)
foreach ($l in $linhas) {
    $l | Add-Member -NotePropertyName PREFIXO_FROTA -NotePropertyValue (Formata-Prefixo $l.PREFIXO) -Force
    $l | Add-Member -NotePropertyName LITROS_IMPLICITO -NotePropertyValue ($l.KM_PERCORRIDO / $l.KM_POR_L) -Force
}

$agora = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")

foreach ($garagem in $GARAGEM_MAP) {
    $pref = $garagem.prefixoFrota
    $gid  = $garagem.gid
    $cod  = $garagem.cod

    Write-Host ""
    Write-Host "=== $cod (prefixo $pref.xxx) ===" -ForegroundColor Yellow

    $doGaragem = $linhas | Where-Object { $_.PREFIXO_FROTA -like "$pref.*" }
    Write-Host "  $($doGaragem.Count) abastecimentos dessa garagem."

    # Agrega por (data, veiculo, motorista, linha) -- 1 linha por combinacao/dia
    $registros = $doGaragem | Group-Object { "$($_.DATA_ABASTECIMENTO.ToString('yyyy-MM-dd'))~$($_.PREFIXO_FROTA)~$($_.CODIGO_MOTORISTA)~$($_.CODIGO_LINHA)" } | ForEach-Object {
        $km = ($_.Group | Measure-Object KM_PERCORRIDO -Sum).Sum
        $lt = ($_.Group | Measure-Object LITROS_IMPLICITO -Sum).Sum
        # Hodometro do FIM do dia (maior leitura entre os abastecimentos agrupados) --
        # usado so pra cruzar com o km_hodometro digitado em recolha_checklist e
        # abastecimento_checklist (conferencia pedida pelo Daniel 2026-07-14),
        # nao entra no calculo de km/l (que continua vindo de KM_PERCORRIDO/KM_POR_L).
        $hodFinal = ($_.Group | Measure-Object HODOMETRO_FINAL -Maximum).Maximum
        $primeiro = $_.Group[0]
        [PSCustomObject]@{
            garagem_id      = $gid
            garagem_cod     = $cod
            data            = $primeiro.DATA_ABASTECIMENTO.ToString('yyyy-MM-dd')
            veiculo         = $primeiro.PREFIXO_FROTA
            placa           = $primeiro.PLACA
            motorista_cod   = if ($primeiro.CODIGO_MOTORISTA) { "$($primeiro.CODIGO_MOTORISTA)" } else { "SEM_MOTORISTA" }
            motorista_nome  = $primeiro.NOME_MOTORISTA
            linha           = if ($primeiro.CODIGO_LINHA) { "$($primeiro.CODIGO_LINHA)" } else { "SEM_LINHA" }
            linha_nome      = $primeiro.NOME_LINHA
            km_percorrido   = [Math]::Round($km, 1)
            litros          = [Math]::Round($lt, 2)
            km_l            = if ($lt -gt 0) { [Math]::Round($km / $lt, 2) } else { 0 }
            hodometro_final = $hodFinal
            updated_at      = $agora
        }
    }

    Write-Host "  Limpando registros antigos de $cod..."
    $delUri = "$SUPABASE_URL/rest/v1/instrutor_kml_detalhado?garagem_cod=eq.$cod"
    $delHdr = @{ "apikey" = $SUPABASE_KEY; "Authorization" = "Bearer $SUPABASE_KEY"; "Prefer" = "return=minimal" }
    try { Invoke-RestMethod -Method DELETE -Uri $delUri -Headers $delHdr | Out-Null } catch { Write-Warning "Delete: $_" }

    Write-Host "  Inserindo $($registros.Count) registros..."
    Supabase-Insert "instrutor_kml_detalhado" $registros
    Write-Host "  $cod concluido!" -ForegroundColor Green
}

Write-Host ""
Write-Host "Sync concluido! Janela: $dataInicio ate $dataFim" -ForegroundColor Green
