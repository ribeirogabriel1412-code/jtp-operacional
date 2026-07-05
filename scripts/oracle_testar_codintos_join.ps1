# Testa o vinculo OS <-> custo via CODINTOS: PI_MAN.CODINTOS = EST_REQUISICAO.CODINTOS
# EST_REQUISICAO tem CODINTOS + CODIGOVEIC + NUMERORQ -- pode ser o elo que faltava
# entre a OS de manutencao e o custo de pecas (EST_MOVTO/EST_ITENSOUTENT).
# RODAR NO SERVIDOR. Senha vem de $env:JTP_ORACLE_PWD.

$DSN = "GLOBUSSERVER"
$UID = if ($env:JTP_ORACLE_UID) { $env:JTP_ORACLE_UID } else { "CONSULTA868" }
$PWD_ORACLE = if ($env:JTP_ORACLE_PWD) { $env:JTP_ORACLE_PWD } else { "COLE_AQUI" }
$OUT_FILE = "C:\sync_praxio\relatorios\testar_codintos_join.txt"

$connStr = "DSN=$DSN;UID=$UID;PWD=$PWD_ORACLE"
New-Item -ItemType Directory -Path (Split-Path $OUT_FILE) -Force | Out-Null
if (Test-Path $OUT_FILE) { Remove-Item $OUT_FILE -Force }
function Log($t) { Write-Host $t; Add-Content -Path $OUT_FILE -Value $t -Encoding UTF8 }

Add-Type -AssemblyName System.Data
$conn = New-Object System.Data.Odbc.OdbcConnection
$conn.ConnectionString = $connStr
$conn.Open()
Log "Conectado -- $(Get-Date)"

function Roda-Query($sql, $timeout = 120) {
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

# -- Teste 1: pega uma OS real de junho/PVH com CONDICAO_OS fechada, ve se tem
# requisicao de peca vinculada via CODINTOS -----------------------------------
Log ""
Log "=== Teste 1: OS reais de PVH/junho com requisicao vinculada (via CODINTOS) ==="
try {
    $sql1 = @"
SELECT p.NUMERO_OS, p.CODINTOS, p.PREFIXO_VEIC, p.DATA_OS, p.CONDICAO_OS,
       r.NUMERORQ, r.CODIGOVEIC AS CODIGOVEIC_REQ, r.DATARQ
FROM GLOBUS868.PI_MAN p
JOIN GLOBUS868.EST_REQUISICAO r ON r.CODINTOS = p.CODINTOS
WHERE p.FILIAL LIKE '%PORTO VELHO%'
  AND p.DATA_OS >= TO_DATE('2026-06-01','YYYY-MM-DD')
  AND p.DATA_OS <  TO_DATE('2026-07-01','YYYY-MM-DD')
  AND ROWNUM <= 20
"@
    $r1 = Roda-Query $sql1 60
    Log "Linhas encontradas: $($r1.Count)"
    Log ($r1 | Format-Table -AutoSize | Out-String -Width 300)
} catch {
    Log "Falhou: $($_.Exception.Message)"
}

Log ""
Log "=== Teste 2: contagem geral -- quantas OS de PVH/junho tem requisicao vinculada ==="
try {
    $sql2 = @"
SELECT COUNT(DISTINCT p.CODINTOS) AS OS_COM_REQUISICAO
FROM GLOBUS868.PI_MAN p
JOIN GLOBUS868.EST_REQUISICAO r ON r.CODINTOS = p.CODINTOS
WHERE p.FILIAL LIKE '%PORTO VELHO%'
  AND p.DATA_OS >= TO_DATE('2026-06-01','YYYY-MM-DD')
  AND p.DATA_OS <  TO_DATE('2026-07-01','YYYY-MM-DD')
"@
    $r2 = Roda-Query $sql2 60
    Log "OS com requisicao vinculada: $($r2[0].OS_COM_REQUISICAO)"
} catch {
    Log "Falhou: $($_.Exception.Message)"
}

# -- Teste 3 (v2): join completo via EST_ITENSREQUISICAO, ja usada em producao
# pelo sync_praxio.ps1 pra calcular custo_real -- pula EST_MOVTO/EST_ITENSOUTENT
Log ""
Log "=== Teste 3: JOIN completo OS -> requisicao -> ITENS requisicao -> material ==="
try {
    $sql3 = @"
SELECT p.NUMERO_OS, p.PREFIXO_VEIC, p.CONDICAO_OS, r.NUMERORQ,
       c.DESCRICAOMAT, it.QTDEITREQ, it.VALORITREQ, it.VALORTOTALITREQ, it.STATUSITREQ
FROM GLOBUS868.PI_MAN p
JOIN GLOBUS868.EST_REQUISICAO r ON r.CODINTOS = p.CODINTOS
JOIN GLOBUS868.EST_ITENSREQUISICAO it ON it.NUMERORQ = r.NUMERORQ
JOIN GLOBUS868.EST_CADMATERIAL c ON c.CODIGOMATINT = it.CODIGOMATINT
WHERE p.FILIAL LIKE '%PORTO VELHO%'
  AND p.DATA_OS >= TO_DATE('2026-06-01','YYYY-MM-DD')
  AND p.DATA_OS <  TO_DATE('2026-07-01','YYYY-MM-DD')
  AND ROWNUM <= 20
"@
    $r3 = Roda-Query $sql3 60
    Log "Linhas encontradas: $($r3.Count)"
    Log ($r3 | Format-Table -AutoSize | Out-String -Width 300)
} catch {
    Log "Falhou: $($_.Exception.Message)"
}

$conn.Close()
Log ""
Log "Concluido em $(Get-Date). Arquivo salvo em: $OUT_FILE"
