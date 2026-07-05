# Busca a definicao real da view VW_LANCAMENTOABASTECIMENTO pra entender
# exatamente o que causa "ORA-01476: divisor e igual a zero" -- objetivo e
# contornar so o calculo problematico, sem descartar o dia inteiro (isso
# estava causando motoristas sumirem do cruzamento com viagens).
# RODAR NO SERVIDOR. Senha vem de $env:JTP_ORACLE_PWD.

$DSN = "GLOBUSSERVER"
$UID = if ($env:JTP_ORACLE_UID) { $env:JTP_ORACLE_UID } else { "CONSULTA868" }
$PWD_ORACLE = if ($env:JTP_ORACLE_PWD) { $env:JTP_ORACLE_PWD } else { "COLE_AQUI" }
$OUT_FILE = "C:\sync_praxio\relatorios\definicao_view_abastecimento.txt"

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

Log ""
Log "=== Texto da view VW_LANCAMENTOABASTECIMENTO ==="
try {
    $r1 = Roda-Query "SELECT TEXT FROM ALL_VIEWS WHERE OWNER = 'GLOBUS868' AND VIEW_NAME = 'VW_LANCAMENTOABASTECIMENTO'"
    if ($r1.Count -gt 0) {
        Log $r1[0].TEXT
    } else {
        Log "(nao encontrado em ALL_VIEWS -- tentando LONG via DBMS_METADATA)"
        $r2 = Roda-Query "SELECT DBMS_METADATA.GET_DDL('VIEW','VW_LANCAMENTOABASTECIMENTO','GLOBUS868') AS DDL FROM DUAL"
        Log $r2[0].DDL
    }
} catch {
    Log "Falhou: $($_.Exception.Message)"
}

Log ""
Log "=== Achar um dia especifico que sabemos que falha (pra achar a linha exata) ==="
Log "Testando dia a dia dentro de uma semana conhecida com erro (maio/2026)..."
foreach ($dia in @("2026-05-11","2026-05-12","2026-05-13")) {
    try {
        $r3 = Roda-Query "SELECT COUNT(*) AS QTD FROM GLOBUS868.VW_LANCAMENTOABASTECIMENTO WHERE DATA_ABASTECIMENTO >= TO_DATE('$dia','YYYY-MM-DD') AND DATA_ABASTECIMENTO < TO_DATE('$dia','YYYY-MM-DD')+1 AND PLACA IS NOT NULL"
        Log "  $dia -- OK, count sem KM_POR_L: $($r3[0].QTD)"
    } catch {
        Log "  $dia -- FALHOU mesmo sem tocar KM_POR_L: $($_.Exception.Message)"
    }
}

Log ""
Log "=== Teste: incluindo KM_POR_L, mas filtrando QUANTIDADE_COMBUSTIVEL <> 0 ==="
foreach ($dia in @("2026-05-11","2026-05-12","2026-05-13")) {
    try {
        $r4 = Roda-Query "SELECT COUNT(*) AS QTD FROM GLOBUS868.VW_LANCAMENTOABASTECIMENTO WHERE DATA_ABASTECIMENTO >= TO_DATE('$dia','YYYY-MM-DD') AND DATA_ABASTECIMENTO < TO_DATE('$dia','YYYY-MM-DD')+1 AND PLACA IS NOT NULL AND QUANTIDADE_COMBUSTIVEL <> 0 AND KM_POR_L IS NOT NULL"
        Log "  $dia -- OK, count com KM_POR_L (QUANTIDADE_COMBUSTIVEL<>0): $($r4[0].QTD)"
    } catch {
        Log "  $dia -- FALHOU: $($_.Exception.Message)"
    }
}

Log ""
Log "=== Teste alternativo: filtrando so por HODOMETRO_FINAL <> HODOMETRO_INICIAL ==="
foreach ($dia in @("2026-05-11","2026-05-12","2026-05-13")) {
    try {
        $r5 = Roda-Query "SELECT COUNT(*) AS QTD FROM GLOBUS868.VW_LANCAMENTOABASTECIMENTO WHERE DATA_ABASTECIMENTO >= TO_DATE('$dia','YYYY-MM-DD') AND DATA_ABASTECIMENTO < TO_DATE('$dia','YYYY-MM-DD')+1 AND PLACA IS NOT NULL AND KM_PERCORRIDO IS NOT NULL AND KM_POR_L IS NOT NULL"
        Log "  $dia -- OK, count com KM_POR_L (so IS NOT NULL): $($r5[0].QTD)"
    } catch {
        Log "  $dia -- FALHOU: $($_.Exception.Message)"
    }
}

$conn.Close()
Log ""
Log "Concluido em $(Get-Date). Arquivo salvo em: $OUT_FILE"
