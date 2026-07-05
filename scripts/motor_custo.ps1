# Motor de Custo por Veiculo -- JTP Transportes
# Cruza OS de manutencao (PI_MAN) com requisicao de pecas (EST_REQUISICAO) e
# itens/valores (EST_ITENSREQUISICAO + EST_CADMATERIAL pra descricao).
#
# JOIN descoberto em 2026-07-05:
#   PI_MAN.CODINTOS = EST_REQUISICAO.CODINTOS (elo real, NAO usar NUMERO_OS que recicla)
#   EST_REQUISICAO.NUMERORQ = EST_ITENSREQUISICAO.NUMERORQ
#   EST_ITENSREQUISICAO.CODIGOMATINT = EST_CADMATERIAL.CODIGOMATINT
#
# IMPORTANTE (2026-07-05): testado contra 8 itens reais do painel de custo SAP --
# NAO existe uma escala unica (nem sempre /100, nem sempre direto). Alguns
# materiais batem exato (razao=1), outros tem erro de cadastro de preco na
# origem (razao ~100), outros tem preco genuinamente diferente por lote/data
# (razao aleatoria tipo 84, 116). Isso e ruido de dado real, nao um bug nosso
# corrigivel com formula.
#
# Decisao (a pedido de Daniel): nao tentar "consertar" valor por valor. Em vez
# disso, tratar o custo como ESTIMATIVA -- separar QUANTIDADE DE ITENS (100%
# confiavel, nao tem problema de escala) do CUSTO (estimado, com aviso). Marca
# como "suspeito" qualquer item com custo/unidade acima de um limite implausivel
# (R$ 50.000/unidade) e exclui do total estimado, mas mantem contado.
#
# NAO grava nada no Supabase -- etapa de validacao manual dos calculos.
# RODAR NO SERVIDOR (unico lugar com IP liberado no ODBC GLOBUSSERVER).
# Senha vem de $env:JTP_ORACLE_PWD (setar antes de rodar, nunca colar aqui).
#
# USO:
#   .\motor_custo.ps1 -DataInicio "2026-06-01" -DataFim "2026-06-30" -Garagem PVH

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

Write-Host "Motor de Custo por Veiculo" -ForegroundColor Yellow
Write-Host "Periodo: $DataInicio ate $DataFim | Garagem: $(if ($Garagem) { $Garagem } else { 'Todas' })" -ForegroundColor Yellow

# Converte prefixo bruto do Oracle pro formato da frota (mesma regra do PRAXIO)
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
SELECT p.NUMERO_OS, p.PREFIXO_VEIC, p.FILIAL, p.DATA_OS, p.CONDICAO_OS, p.TIPOOS,
       r.NUMERORQ, c.DESCRICAOMAT, it.QTDEITREQ, it.VALORTOTALITREQ, it.STATUSITREQ
FROM (
    -- PI_MAN tem multiplas linhas por OS (audit trail -- cada alteracao vira
    -- linha nova). Precisa deduplicar por CODINTOS ANTES do join, senao cada
    -- linha repetida do PI_MAN multiplica o custo (fan-out ja confirmado: OS
    -- com 20 linhas no PI_MAN gerava o custo 20x maior).
    SELECT CODINTOS, MIN(NUMERO_OS) AS NUMERO_OS, MIN(PREFIXO_VEIC) AS PREFIXO_VEIC,
           MIN(FILIAL) AS FILIAL, MIN(DATA_OS) AS DATA_OS,
           MAX(CONDICAO_OS) AS CONDICAO_OS, MIN(TIPOOS) AS TIPOOS
    FROM GLOBUS868.PI_MAN
    WHERE DATA_OS >= TO_DATE('$DataInicio','YYYY-MM-DD')
      AND DATA_OS <= TO_DATE('$DataFim','YYYY-MM-DD') + 1
      $filtroFilial
    GROUP BY CODINTOS
) p
JOIN GLOBUS868.EST_REQUISICAO r ON r.CODINTOS = p.CODINTOS
JOIN GLOBUS868.EST_ITENSREQUISICAO it ON it.NUMERORQ = r.NUMERORQ
JOIN GLOBUS868.EST_CADMATERIAL c ON c.CODIGOMATINT = it.CODIGOMATINT
"@
$linhas = Roda-Query $sql 180
Write-Host "$($linhas.Count) itens de requisicao encontrados." -ForegroundColor Green

if ($linhas.Count -eq 0) {
    Write-Host "Nenhum dado encontrado no periodo." -ForegroundColor Red
    $conn.Close()
    return
}

# -- Marca itens com custo/unidade implausivel (limite ajustavel) -----------
$LIMITE_CUSTO_UNITARIO = 50000
foreach ($l in $linhas) {
    $qtd = if ($l.QTDEITREQ -and $l.QTDEITREQ -ne 0) { $l.QTDEITREQ } else { 1 }
    $custoUnit = $l.VALORTOTALITREQ / $qtd
    $l | Add-Member -NotePropertyName SUSPEITO -NotePropertyValue ($custoUnit -gt $LIMITE_CUSTO_UNITARIO) -Force
}

# -- Agregado por veiculo ---------------------------------------------------
# Quantidade de itens = 100% confiavel (nao depende de valor). Custo estimado
# = soma dos itens NAO suspeitos (exclui outliers implausiveis do total, mas
# continua contando a quantidade normalmente).
$porVeiculo = $linhas | Group-Object PREFIXO_VEIC | ForEach-Object {
    $normais = @($_.Group | Where-Object { -not $_.SUSPEITO })
    $suspeitos = @($_.Group | Where-Object { $_.SUSPEITO })
    $custoRaw = if ($normais.Count -gt 0) { ($normais | Measure-Object VALORTOTALITREQ -Sum).Sum } else { 0 }
    $osUnicas = @($_.Group | Select-Object -ExpandProperty NUMERO_OS -Unique)
    [PSCustomObject]@{
        prefixo           = Formata-Prefixo $_.Name
        qtd_os            = $osUnicas.Count
        qtd_itens         = $_.Count
        qtd_itens_suspeitos = $suspeitos.Count
        custo_estimado    = [Math]::Round($custoRaw, 2)
    }
} | Sort-Object custo_estimado -Descending

# -- Total geral ------------------------------------------------------------
$linhasNormais = @($linhas | Where-Object { -not $_.SUSPEITO })
$linhasSuspeitas = @($linhas | Where-Object { $_.SUSPEITO })
$custoGeral = ($linhasNormais | Measure-Object VALORTOTALITREQ -Sum).Sum
$osUnicasGeral = @($linhas | Select-Object -ExpandProperty NUMERO_OS -Unique)

Write-Host ""
Write-Host "=== TOTAL DO PERIODO ===" -ForegroundColor Cyan
Write-Host "OS unicas: $($osUnicasGeral.Count) | Itens: $($linhas.Count) ($($linhasSuspeitas.Count) suspeitos, excluidos do custo) | Custo ESTIMADO: R$ $([Math]::Round($custoGeral,2))" -ForegroundColor Cyan
Write-Host "(custo e estimativa -- alguns materiais tem preco de cadastro inconsistente na origem, nao e numero contabil exato)" -ForegroundColor DarkGray
Write-Host ""
Write-Host "--- Top 15 veiculos por custo estimado ---" -ForegroundColor Yellow
$porVeiculo | Select-Object -First 15 | Format-Table -AutoSize

$sufixo = "$($DataInicio)_a_$($DataFim)_$(if ($Garagem) { $Garagem } else { 'todas' })"
$linhas     | Export-Csv -Path "$OUT_DIR\custo_detalhe_$sufixo.csv"   -NoTypeInformation -Encoding UTF8
$porVeiculo | Export-Csv -Path "$OUT_DIR\custo_por_veiculo_$sufixo.csv" -NoTypeInformation -Encoding UTF8

$conn.Close()
Write-Host ""
Write-Host "CSVs salvos em $OUT_DIR" -ForegroundColor Green
