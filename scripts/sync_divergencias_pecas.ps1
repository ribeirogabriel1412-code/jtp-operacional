# Cruza requisicoes_compra (nosso app, Supabase) com a Oracle/PRAXIO pra achar
# divergencia entre o que o time lancou no app e o que esta registrado na
# origem oficial. Roda periodicamente (Task Scheduler) a partir de 2026-07-06.
#
# So valida linhas de requisicoes_compra que tem os_numero preenchido (vinculo
# com a OS da Oracle) -- linhas sem os_numero (pedido avulso, sem OS formal)
# ficam de fora, nao tem como cruzar.
#
# Match: (os_numero, cod_sap) -- confirmado que cod_sap do app bate com
# EST_CADMATERIAL.CODIGOMATINT da Oracle (mesmo formato numerico).
#
# RODAR NO SERVIDOR. Senha vem de $env:JTP_ORACLE_PWD.

$DSN = "GLOBUSSERVER"
$UID = if ($env:JTP_ORACLE_UID) { $env:JTP_ORACLE_UID } else { "CONSULTA868" }
$PWD_ORACLE = if ($env:JTP_ORACLE_PWD) { $env:JTP_ORACLE_PWD } else { "COLE_AQUI" }

$SUPABASE_URL = "https://yxwxcxdegkvjvwchemsm.supabase.co"
$SUPABASE_KEY = "sb_publishable_SvC1D0cMk94sZ_9kYv41QQ_RJVrSuUV"
$GARAGEM_ID_PVH = "aaaaaaaa-0001-0000-0000-000000000001"

$hdr = @{ "apikey" = $SUPABASE_KEY; "Authorization" = "Bearer $SUPABASE_KEY" }
$hdrWrite = $hdr + @{ "Content-Type" = "application/json"; "Prefer" = "return=minimal,resolution=merge-duplicates" }

Write-Host "=== Sync Divergencias Pecas x PRAXIO -- $(Get-Date) ===" -ForegroundColor Yellow

# -- 1) Busca no Supabase as requisicoes com os_numero preenchido -----------
Write-Host "Buscando requisicoes_compra com os_numero..." -ForegroundColor Cyan
$reqs = Invoke-RestMethod -Method GET -Headers $hdr -Uri "$SUPABASE_URL/rest/v1/requisicoes_compra?os_numero=not.is.null&select=*"
$reqs = @($reqs | Where-Object { $_.os_numero -match '^\d+$' })
Write-Host "$($reqs.Count) requisicoes com OS numerica valida." -ForegroundColor Green

if ($reqs.Count -eq 0) {
    Write-Host "Nada pra validar ainda." -ForegroundColor Yellow
    return
}

$osNumeros = @($reqs | Select-Object -ExpandProperty os_numero -Unique)
Write-Host "OS unicas a checar: $($osNumeros -join ', ')" -ForegroundColor Cyan

# -- 2) Consulta a Oracle so pras OS que interessam -------------------------
Add-Type -AssemblyName System.Data
$conn = New-Object System.Data.Odbc.OdbcConnection
$conn.ConnectionString = "DSN=$DSN;UID=$UID;PWD=$PWD_ORACLE"
$conn.Open()

function Roda-Query($sql, $timeout = 120) {
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

$listaOs = ($osNumeros | ForEach-Object { "'$_'" }) -join ','
# IMPORTANTE (2026-07-06): CODIGOMATINT e codigo INTERNO da Oracle, nao e o
# mesmo que o cod_sap (8 digitos, tipo 30016636) usado no app. O campo que
# corresponde ao cod_sap e CODIGOINTERNOMATERIAL -- confirmado testando
# (buscamos o valor "30001845" em todas as colunas de EST_CADMATERIAL e so
# apareceu em CODIGOINTERNOMATERIAL/CODIGOORIGINALMAT/CODIGOPARALELO3MAT).
# O JOIN interno continua por CODIGOMATINT (isso esta certo, e a chave real
# entre EST_ITENSREQUISICAO e EST_CADMATERIAL) -- so trocamos qual coluna
# exportamos pra comparar com o app.
$sql = @"
SELECT p.NUMERO_OS, c.CODIGOINTERNOMATERIAL AS COD_SAP, c.DESCRICAOMAT, SUM(it.QTDEITREQ) AS QTD_ORACLE
FROM (
    SELECT CODINTOS, MIN(NUMERO_OS) AS NUMERO_OS
    FROM GLOBUS868.PI_MAN
    WHERE NUMERO_OS IN ($listaOs)
    GROUP BY CODINTOS
) p
JOIN GLOBUS868.EST_REQUISICAO r ON r.CODINTOS = p.CODINTOS
JOIN GLOBUS868.EST_ITENSREQUISICAO it ON it.NUMERORQ = r.NUMERORQ
JOIN GLOBUS868.EST_CADMATERIAL c ON c.CODIGOMATINT = it.CODIGOMATINT
GROUP BY p.NUMERO_OS, c.CODIGOINTERNOMATERIAL, c.DESCRICAOMAT
"@
Write-Host "Consultando Oracle..." -ForegroundColor Cyan
$oracleRows = Roda-Query $sql 120
$conn.Close()
Write-Host "$($oracleRows.Count) linhas de material encontradas na Oracle pras OS pedidas." -ForegroundColor Green

# Mapa (NUMERO_OS|COD_SAP) -> qtd Oracle
$mapOracle = @{}
foreach ($o in $oracleRows) {
    $k = "$($o.NUMERO_OS)|$($o.COD_SAP)"
    $mapOracle[$k] = $o.QTD_ORACLE
}

Write-Host ""
Write-Host "--- DEBUG: chaves da Oracle (NUMERO_OS|CODIGOMATINT) ---" -ForegroundColor DarkGray
foreach ($k in $mapOracle.Keys) { Write-Host "  [$k]" -ForegroundColor DarkGray }
Write-Host "--- DEBUG: chaves do app (os_numero|cod_sap) ---" -ForegroundColor DarkGray
foreach ($r in $reqs) { if ($r.cod_sap) { Write-Host "  [$($r.os_numero)|$($r.cod_sap)]" -ForegroundColor DarkGray } }

# -- 3) Compara e monta divergencias ----------------------------------------
$divergencias = [System.Collections.Generic.List[object]]::new()
foreach ($r in $reqs) {
    if (-not $r.cod_sap) { continue }  # sem codigo de material, nao da pra cruzar
    $qtdApp = if ($r.qtd_entregue -ne $null) { $r.qtd_entregue } else { $r.quantidade }
    $k = "$($r.os_numero)|$($r.cod_sap)"
    if (-not $mapOracle.ContainsKey($k)) {
        $divergencias.Add([PSCustomObject]@{
            garagem_id = $r.garagem_id
            requisicao_id = $r.id
            os_numero = $r.os_numero
            prefixo = $r.prefixo
            cod_sap = $r.cod_sap
            peca = $r.peca
            qtd_app = $qtdApp
            qtd_oracle = $null
            tipo_divergencia = "sem_match_oracle"
            detalhe = "App registra esse material na OS $($r.os_numero), mas nao achei ele na requisicao Oracle dessa OS."
        })
    } elseif ([Math]::Abs($mapOracle[$k] - $qtdApp) -gt 0.01) {
        $divergencias.Add([PSCustomObject]@{
            garagem_id = $r.garagem_id
            requisicao_id = $r.id
            os_numero = $r.os_numero
            prefixo = $r.prefixo
            cod_sap = $r.cod_sap
            peca = $r.peca
            qtd_app = $qtdApp
            qtd_oracle = $mapOracle[$k]
            tipo_divergencia = "qtd_diferente"
            detalhe = "App registra qtd $qtdApp, Oracle registra qtd $($mapOracle[$k]) pra esse material na OS $($r.os_numero)."
        })
    }
}

Write-Host ""
Write-Host "$($divergencias.Count) divergencia(s) encontrada(s) de $($reqs.Count) requisicoes checadas." -ForegroundColor $(if ($divergencias.Count -gt 0) { "Red" } else { "Green" })
$divergencias | Format-Table os_numero, prefixo, tipo_divergencia, qtd_app, qtd_oracle, peca -AutoSize

# -- 4) Grava no Supabase (upsert por UNIQUE os_numero+cod_sap+tipo) --------
if ($divergencias.Count -gt 0) {
    $body = $divergencias | ConvertTo-Json -Depth 3
    if ($divergencias.Count -eq 1) { $body = "[$body]" }
    try {
        Invoke-RestMethod -Method POST -Uri "$SUPABASE_URL/rest/v1/divergencias_pecas_praxio" -Headers $hdrWrite -Body $body | Out-Null
        Write-Host "Divergencias gravadas em divergencias_pecas_praxio." -ForegroundColor Green
    } catch {
        Write-Warning "Erro gravando divergencias: $($_.Exception.Message)"
    }
}


# -- 5) Popula qtd_praxio em almoxo_inventario_turno -------------------------
# Cada linha do inventario de turno tem req_id (= id de requisicoes_compra).
# Usa o mesmo mapOracle ja consultado (mesma OS+material) pra preencher
# qtd_praxio, sem nova consulta a Oracle.
Write-Host ""
Write-Host "Atualizando qtd_praxio em almoxo_inventario_turno..." -ForegroundColor Cyan
$reqById = @{}
foreach ($r in $reqs) { $reqById["$($r.id)"] = $r }

$turnoRows = Invoke-RestMethod -Method GET -Headers $hdr -Uri "$SUPABASE_URL/rest/v1/almoxo_inventario_turno?qtd_praxio=is.null&select=id,req_id,qtd_fisica"
$turnoRows = @($turnoRows)
Write-Host "$($turnoRows.Count) linhas de inventario de turno sem qtd_praxio ainda." -ForegroundColor Cyan

$atualizados = 0
foreach ($t in $turnoRows) {
    $req = $reqById["$($t.req_id)"]
    if (-not $req -or -not $req.cod_sap) { continue }
    $k = "$($req.os_numero)|$($req.cod_sap)"
    if (-not $mapOracle.ContainsKey($k)) { continue }
    $qtdPraxio = $mapOracle[$k]
    $acuracia = if ($qtdPraxio -gt 0) { [Math]::Round(($t.qtd_fisica / $qtdPraxio) * 100, 1) } else { $null }
    $patchBody = @{ qtd_praxio = $qtdPraxio; acuracia = $acuracia } | ConvertTo-Json
    try {
        Invoke-RestMethod -Method PATCH -Uri "$SUPABASE_URL/rest/v1/almoxo_inventario_turno?id=eq.$($t.id)" -Headers $hdrWrite -Body $patchBody | Out-Null
        $atualizados++
    } catch {
        Write-Warning "Erro atualizando turno id $($t.id): $($_.Exception.Message)"
    }
}
Write-Host "$atualizados linha(s) de almoxo_inventario_turno atualizada(s) com qtd_praxio." -ForegroundColor Green

Write-Host ""
Write-Host "Concluido em $(Get-Date)." -ForegroundColor Green
