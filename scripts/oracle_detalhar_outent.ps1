# Detalha tabelas candidatas para "baixa de peca por veiculo" (o Excel de custo/SAP
# que Daniel exportou tem DATA, CODIGO, DESCRICAO, QTD, TOTAL, PREFIXO).
# "OUTENT" parece significar saida de estoque -- testa as tabelas com esse padrao.
# RODAR NO SERVIDOR. Senha vem de $env:JTP_ORACLE_PWD.

$DSN = "GLOBUSSERVER"
$UID = if ($env:JTP_ORACLE_UID) { $env:JTP_ORACLE_UID } else { "CONSULTA868" }
$PWD_ORACLE = if ($env:JTP_ORACLE_PWD) { $env:JTP_ORACLE_PWD } else { "COLE_AQUI" }
$OUT_FILE = "C:\sync_praxio\relatorios\detalhe_outent.txt"

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

# Busca ampla: tabelas com coluna de veiculo E coluna de valor/preco juntas
Log ""
Log "=== Tabelas com OUTENT no nome (possivel saida de estoque) ==="
$r0 = Roda-Query "SELECT DISTINCT OWNER, TABLE_NAME FROM ALL_TABLES WHERE TABLE_NAME LIKE '%OUTENT%'"
$r0 | Format-Table -AutoSize | Out-String -Width 200 | ForEach-Object { Log $_ }

$tabelas = @("GLOBUS868.EST_ITENSOUTENT", "GLOBUS868.EST_SERVOUTENT", "GLOBUS868.EST_MOVTO")

foreach ($t in $tabelas) {
    $partes = $t -split '\.', 2
    $owner = $partes[0]; $nome = $partes[1]
    Log ""
    Log "--- $t ---"
    try {
        $cols = Roda-Query "SELECT COLUMN_NAME, DATA_TYPE FROM ALL_TAB_COLUMNS WHERE OWNER = '$owner' AND TABLE_NAME = '$nome' ORDER BY COLUMN_ID"
        if ($cols.Count -eq 0) { Log "(tabela nao encontrada)"; continue }
        $colunas = @()
        foreach ($c in $cols) { $colunas += "$($c.COLUMN_NAME) ($($c.DATA_TYPE))" }
        Log "Colunas ($($cols.Count)): $($colunas -join ', ')"
    } catch {
        Log "  (falha ao ler colunas: $($_.Exception.Message))"
        continue
    }
    try {
        $amostra = Roda-Query "SELECT * FROM $t WHERE ROWNUM <= 5" 30
        Log "Amostra:"
        Log ($amostra | Format-Table -AutoSize | Out-String -Width 300)
    } catch {
        Log "  (falha ao ler amostra: $($_.Exception.Message))"
    }
}

$conn.Close()
Log ""
Log "Concluido em $(Get-Date). Arquivo salvo em: $OUT_FILE"
