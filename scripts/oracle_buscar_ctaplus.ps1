# Busca tabelas Oracle que possam ser a versao completa do export CTAPLUS
# (a ABA_IMPORT_CTAPLUS_TMP que achamos antes so tem 3 colunas -- deve ser so
# estagio temporario de importacao). Busca por nomes de coluna reais do Excel:
# PLACA, DISTANCIA, ODOMETRO, HORIMETRO, ENCERRANTE, POSTO, FRENTISTA, VOLUME.
#
# RODAR NO SERVIDOR. Senha vem de $env:JTP_ORACLE_PWD.

$DSN = "GLOBUSSERVER"
$UID = if ($env:JTP_ORACLE_UID) { $env:JTP_ORACLE_UID } else { "CONSULTA868" }
$PWD_ORACLE = if ($env:JTP_ORACLE_PWD) { $env:JTP_ORACLE_PWD } else { "COLE_AQUI" }
$OUT_FILE = "C:\sync_praxio\relatorios\busca_ctaplus.txt"

$connStr = "DSN=$DSN;UID=$UID;PWD=$PWD_ORACLE"
New-Item -ItemType Directory -Path (Split-Path $OUT_FILE) -Force | Out-Null
if (Test-Path $OUT_FILE) { Remove-Item $OUT_FILE -Force }
function Log($t) { Write-Host $t; Add-Content -Path $OUT_FILE -Value $t -Encoding UTF8 }

Add-Type -AssemblyName System.Data
$conn = New-Object System.Data.Odbc.OdbcConnection
$conn.ConnectionString = $connStr
$conn.Open()
Log "Conectado -- $(Get-Date)"

function Roda-Query($sql, $timeout = 60) {
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
            catch { $val = "<erro leitura>" }
            $obj[$colNames[$c]] = $val
        }
        $resultados.Add([PSCustomObject]$obj)
    }
    $reader.Close()
    return $resultados
}

$padroes = @("%PLACA%", "%DISTANCIA%", "%ODOMETRO%", "%HORIMETRO%", "%ENCERRANTE%", "%POSTO%", "%FRENTISTA%", "%CTAPLUS%", "%VOLUME%")
$candidatas = @{}
foreach ($p in $padroes) {
    try {
        $sql = "SELECT OWNER, TABLE_NAME, COLUMN_NAME FROM ALL_TAB_COLUMNS WHERE COLUMN_NAME LIKE '$p'"
        $linhas = Roda-Query $sql
        Log "Padrao '$p': $($linhas.Count) colunas encontradas"
        foreach ($linha in $linhas) {
            $chave = "$($linha.OWNER).$($linha.TABLE_NAME)"
            if (-not $candidatas.ContainsKey($chave)) { $candidatas[$chave] = @() }
            $candidatas[$chave] += $linha.COLUMN_NAME
        }
    } catch {
        Log "Padrao '$p' falhou: $($_.Exception.Message)"
    }
}

$ordenadas = $candidatas.GetEnumerator() | Sort-Object { $_.Value.Count } -Descending
Log ""
Log "Tabelas candidatas (ordenadas por qtd de colunas batidas):"
foreach ($item in @($ordenadas)) {
    Log "  $($item.Key) -- colunas: $($item.Value -join ', ')"
}

$conn.Close()
Log ""
Log "Concluido em $(Get-Date). Arquivo salvo em: $OUT_FILE"
