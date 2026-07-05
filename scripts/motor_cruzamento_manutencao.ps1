# Motor de Cruzamento: Viagens Perdidas x Manutencao -- JTP Transportes
# Pra cada (dia, veiculo) com viagem perdida, verifica se o veiculo tinha OS
# aberta no Oracle (PI_MAN) naquele dia -- causa provavel da perda.
#
# Fontes: Azure Blob (viagens, mesmo padrao do motor_viagens_perdidas.ps1)
#         + Oracle PI_MAN (OS de manutencao, sob demanda, sem pre-agregar)
#
# NAO grava nada no Supabase -- etapa de validacao manual.
# RODAR NO SERVIDOR (unico lugar com acesso a Azure Blob E Oracle ao mesmo tempo).
#
# Credenciais vem de variaveis de ambiente (setar antes, nunca colar aqui):
#   $env:JTP_AZURE_STORAGE_CONN
#   $env:JTP_ORACLE_UID / $env:JTP_ORACLE_PWD
#
# USO:
#   .\motor_cruzamento_manutencao.ps1 -DataInicio "2026-06-01" -DataFim "2026-06-30" -Garagem "carlos.jtp"

param(
    [string]$DataInicio,
    [string]$DataFim,
    [string]$Garagem = "carlos.jtp"  # prefixo do blob: "Jessica" (Porto Velho) ou "carlos.jtp" (Braganca)
)

# -- Configuracao ---------------------------------------------------------
$AZURE_CONN  = if ($env:JTP_AZURE_STORAGE_CONN) { $env:JTP_AZURE_STORAGE_CONN } else { "COLE_AQUI" }
$CONTAINER   = "1-raw"
$BLOB_PREFIX = "CITTATI/JSON_VIAGENS"

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

Write-Host "Motor de Cruzamento: Viagens Perdidas x Manutencao" -ForegroundColor Yellow
Write-Host "Periodo: $DataInicio ate $DataFim | Garagem (blob): $Garagem" -ForegroundColor Yellow

# Converte prefixo bruto do Oracle pro formato da frota (mesma regra do PRAXIO)
function Formata-Prefixo($raw) {
    $s = "$raw".Trim()
    if ($s.Length -ge 5 -and $s -match '^\d+$') {
        $last5 = $s.Substring($s.Length - 5)
        return $last5.Substring(0,2) + "." + $last5.Substring(2)
    }
    return $s
}

# ===========================================================================
# PARTE 1 -- Viagens perdidas por (dia, veiculo), direto do Azure Blob
# ===========================================================================
Write-Host ""
Write-Host "--- Parte 1: baixando viagens do Azure Blob ---" -ForegroundColor Cyan
Import-Module Az.Storage -ErrorAction Stop
$ctx = New-AzStorageContext -ConnectionString $AZURE_CONN
$tmpDir = "$OUT_DIR\tmp_cruzamento"
New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null

$inicio = [datetime]::ParseExact($DataInicio, "yyyy-MM-dd", $null)
$fim    = [datetime]::ParseExact($DataFim, "yyyy-MM-dd", $null)
$dias = @(); $d = $inicio; while ($d -le $fim) { $dias += $d; $d = $d.AddDays(1) }

$perdidasPorDiaVeiculo = [System.Collections.Generic.List[object]]::new()

foreach ($dia in $dias) {
    $sufixo = $dia.ToString("dd_MM_yyyy")
    $blob   = "$BLOB_PREFIX/$Garagem $sufixo.json"
    $tmp    = "$tmpDir\${Garagem}_${sufixo}.json"
    $dataISO = $dia.ToString("yyyy-MM-dd")

    try {
        Get-AzStorageBlobContent -Container $CONTAINER -Blob $blob -Destination $tmp -Context $ctx -Force -ErrorAction Stop | Out-Null
    } catch { continue }

    $json = Get-Content $tmp -Raw -Encoding UTF8 | ConvertFrom-Json
    $viagens = $json.viagens | Where-Object { $_.atividade -eq "Viagem Normal" -and $_.veiculo }
    if (-not $viagens) { continue }

    $porVeic = $viagens | Group-Object veiculo
    foreach ($g in $porVeic) {
        $programadas = $g.Count
        $realizadas  = ($g.Group | Where-Object { $null -ne $_.inicioRealizado }).Count
        $perdidas    = $programadas - $realizadas
        if ($perdidas -gt 0) {
            $perdidasPorDiaVeiculo.Add([PSCustomObject]@{
                data       = $dataISO
                veiculo    = $g.Name
                programadas = $programadas
                realizadas  = $realizadas
                perdidas    = $perdidas
            })
        }
    }
}
Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "$($perdidasPorDiaVeiculo.Count) combinacoes (dia+veiculo) com viagem perdida encontradas." -ForegroundColor Green

if ($perdidasPorDiaVeiculo.Count -eq 0) {
    Write-Host "Nenhuma viagem perdida no periodo -- nada pra cruzar." -ForegroundColor Red
    return
}

# ===========================================================================
# PARTE 2 -- OS de manutencao no Oracle (PI_MAN) no mesmo periodo
# ===========================================================================
Write-Host ""
Write-Host "--- Parte 2: consultando OS no Oracle (PI_MAN) ---" -ForegroundColor Cyan
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

# Pega OS que se sobrepoem ao periodo (aberta antes/durante e fechada durante/depois,
# ou ainda em aberto -- DATA_FECHAMENTO nula)
$sqlOS = @"
SELECT NUMERO_OS, PREFIXO_VEIC, DATA_OS, DATA_FECHAMENTO, CONDICAO_OS, TIPOOS, DEFEITO, GRUPO_DEFEITO
FROM GLOBUS868.PI_MAN
WHERE DATA_OS <= TO_DATE('$DataFim','YYYY-MM-DD') + 1
  AND (DATA_FECHAMENTO IS NULL OR DATA_FECHAMENTO >= TO_DATE('$DataInicio','YYYY-MM-DD'))
"@
$osRaw = Roda-Query $sqlOS
Write-Host "$($osRaw.Count) OS encontradas se sobrepondo ao periodo." -ForegroundColor Green
$conn.Close()

foreach ($os in $osRaw) {
    $os | Add-Member -NotePropertyName PREFIXO_FROTA -NotePropertyValue (Formata-Prefixo $os.PREFIXO_VEIC)
}
$osPorVeiculo = $osRaw | Group-Object PREFIXO_FROTA -AsHashTable -AsString

# ===========================================================================
# PARTE 3 -- Cruzamento
# ===========================================================================
Write-Host ""
Write-Host "--- Parte 3: cruzando ---" -ForegroundColor Cyan

$resultado = foreach ($p in $perdidasPorDiaVeiculo) {
    $diaData = [datetime]::ParseExact($p.data, "yyyy-MM-dd", $null)
    $osDoVeiculo = $osPorVeiculo[$p.veiculo]
    $causa = $null
    if ($osDoVeiculo) {
        foreach ($os in $osDoVeiculo) {
            $osInicio = $os.DATA_OS
            $osFim    = if ($os.DATA_FECHAMENTO) { $os.DATA_FECHAMENTO } else { [datetime]::MaxValue }
            if ($diaData -ge $osInicio.Date -and $diaData -le $osFim) {
                $causa = "$($os.TIPOOS): $($os.DEFEITO) (OS $($os.NUMERO_OS), $($os.CONDICAO_OS))"
                break
            }
        }
    }
    [PSCustomObject]@{
        data        = $p.data
        veiculo     = $p.veiculo
        perdidas    = $p.perdidas
        causa_manutencao = if ($causa) { $causa } else { "sem OS encontrada" }
        tem_causa   = if ($causa) { "SIM" } else { "NAO" }
    }
}

$comCausa = @($resultado | Where-Object { $_.tem_causa -eq "SIM" })
$semCausa = @($resultado | Where-Object { $_.tem_causa -eq "NAO" })

$totalPerdidas = ($resultado | Measure-Object perdidas -Sum).Sum
$perdidasComCausa = ($comCausa | Measure-Object perdidas -Sum).Sum
$pctComCausa = if ($totalPerdidas -gt 0) { [Math]::Round(($perdidasComCausa/$totalPerdidas)*100,1) } else { 0 }

Write-Host ""
Write-Host "=== RESULTADO ===" -ForegroundColor Cyan
Write-Host "Combinacoes dia+veiculo com perda: $($resultado.Count) | Total de viagens perdidas: $totalPerdidas" -ForegroundColor Cyan
Write-Host "Com OS de manutencao no dia: $($comCausa.Count) combinacoes ($perdidasComCausa viagens, $pctComCausa%)" -ForegroundColor Cyan
Write-Host "Sem causa de manutencao encontrada: $($semCausa.Count) combinacoes ($($totalPerdidas - $perdidasComCausa) viagens)" -ForegroundColor Cyan
Write-Host ""
Write-Host "--- Top 15 (dia+veiculo) com causa de manutencao encontrada ---" -ForegroundColor Yellow
$comCausa | Sort-Object perdidas -Descending | Select-Object -First 15 | Format-Table -AutoSize -Wrap

$sufixo = "$($DataInicio)_a_$($DataFim)_$Garagem"
$resultado | Export-Csv -Path "$OUT_DIR\cruzamento_manutencao_$sufixo.csv" -NoTypeInformation -Encoding UTF8
Write-Host ""
Write-Host "CSV salvo em $OUT_DIR\cruzamento_manutencao_$sufixo.csv" -ForegroundColor Green
