# Detalha EST_CADMATERIAL (catalogo de materiais) e testa o JOIN completo pra
# reconstruir o painel de custo: EST_MOVTO (data) + EST_ITENSOUTENT (material+valor)
# + EST_CADMATERIAL (descricao) + EST_SERVOUTENT (veiculo, se aplicavel).
# RODAR NO SERVIDOR. Senha vem de $env:JTP_ORACLE_PWD.

$DSN = "GLOBUSSERVER"
$UID = if ($env:JTP_ORACLE_UID) { $env:JTP_ORACLE_UID } else { "CONSULTA868" }
$PWD_ORACLE = if ($env:JTP_ORACLE_PWD) { $env:JTP_ORACLE_PWD } else { "COLE_AQUI" }
$OUT_FILE = "C:\sync_praxio\relatorios\testar_join_custo.txt"

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

Log ""
Log "=== EST_CADMATERIAL: colunas + amostra ==="
$cols = Roda-Query "SELECT COLUMN_NAME, DATA_TYPE FROM ALL_TAB_COLUMNS WHERE OWNER='GLOBUS868' AND TABLE_NAME='EST_CADMATERIAL' ORDER BY COLUMN_ID"
$colunas = @(); foreach ($c in $cols) { $colunas += "$($c.COLUMN_NAME) ($($c.DATA_TYPE))" }
Log "Colunas ($($cols.Count)): $($colunas -join ', ')"
$amostra = Roda-Query "SELECT * FROM GLOBUS868.EST_CADMATERIAL WHERE ROWNUM <= 5" 30
Log ($amostra | Format-Table -AutoSize | Out-String -Width 300)

Log ""
Log "=== Teste do JOIN completo: EST_MOVTO + EST_ITENSOUTENT + EST_CADMATERIAL ==="
Log "(sem veiculo ainda -- so pra ver se a descricao/valor batem com o Excel)"
try {
    $sql = @"
SELECT m.DATAMOVTO, i.CODIGOMATINT, c.DESCRICAOMAT, i.QTDEITENSOUTENT, i.VALORUNITOUTENT
FROM GLOBUS868.EST_MOVTO m
JOIN GLOBUS868.EST_ITENSOUTENT i ON i.NROUTRENT = m.NROUTRENT
JOIN GLOBUS868.EST_CADMATERIAL c ON c.CODIGOMATINT = i.CODIGOMATINT
WHERE m.DATAMOVTO >= TO_DATE('2026-06-25','YYYY-MM-DD')
  AND m.DATAMOVTO <  TO_DATE('2026-06-29','YYYY-MM-DD')
  AND ROWNUM <= 20
"@
    $r = Roda-Query $sql 60
    Log "Linhas: $($r.Count)"
    Log ($r | Format-Table -AutoSize | Out-String -Width 300)
} catch {
    Log "Falhou: $($_.Exception.Message)"
}

Log ""
Log "=== EST_REQUISICAO: colunas completas ==="
try {
    $colsReq = Roda-Query "SELECT COLUMN_NAME, DATA_TYPE FROM ALL_TAB_COLUMNS WHERE OWNER='GLOBUS868' AND TABLE_NAME='EST_REQUISICAO' ORDER BY COLUMN_ID"
    $colunasReq = @(); foreach ($c in $colsReq) { $colunasReq += "$($c.COLUMN_NAME) ($($c.DATA_TYPE))" }
    Log "Colunas ($($colsReq.Count)): $($colunasReq -join ', ')"
    $amostraReq = Roda-Query "SELECT * FROM GLOBUS868.EST_REQUISICAO WHERE ROWNUM <= 5" 30
    Log ($amostraReq | Format-Table -AutoSize | Out-String -Width 300)
} catch {
    Log "Falhou: $($_.Exception.Message)"
}

Log ""
Log "=== JOIN completo COM veiculo (via EST_REQUISICAO pelo NUMERORQ) ==="
try {
    $sql2 = @"
SELECT m.DATAMOVTO, i.CODIGOMATINT, c.DESCRICAOMAT, i.QTDEITENSOUTENT, i.VALORUNITOUTENT, r.CODIGOVEIC
FROM GLOBUS868.EST_MOVTO m
JOIN GLOBUS868.EST_ITENSOUTENT i ON i.NROUTRENT = m.NROUTRENT
JOIN GLOBUS868.EST_CADMATERIAL c ON c.CODIGOMATINT = i.CODIGOMATINT
LEFT JOIN GLOBUS868.EST_REQUISICAO r ON r.NUMERORQ = m.NUMERORQ
WHERE m.DATAMOVTO >= TO_DATE('2026-06-25','YYYY-MM-DD')
  AND m.DATAMOVTO <  TO_DATE('2026-06-29','YYYY-MM-DD')
  AND ROWNUM <= 20
"@
    $r2 = Roda-Query $sql2 60
    Log "Linhas: $($r2.Count)"
    Log ($r2 | Format-Table -AutoSize | Out-String -Width 300)
} catch {
    Log "Falhou: $($_.Exception.Message)"
}

$conn.Close()
Log ""
Log "Concluido em $(Get-Date). Arquivo salvo em: $OUT_FILE"
