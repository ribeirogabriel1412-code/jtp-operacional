# ── Deploy JTP — add + commit + push ──────────────────────
# Clique duplo neste arquivo para publicar as alterações no Vercel

Set-Location $PSScriptRoot

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DEPLOY JTP OPERACIONAL" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Mostra o que mudou
$status = git status --short
if (-not $status) {
    Write-Host "Nenhuma alteracao encontrada. Nada para publicar." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Pressione Enter para fechar"
    exit
}

Write-Host "Arquivos alterados:" -ForegroundColor White
git status --short
Write-Host ""

# Pede a descricao
$msg = Read-Host "O que voce fez? (descreva brevemente)"
if (-not $msg) {
    Write-Host "Descricao nao pode ser vazia. Cancelanddo." -ForegroundColor Red
    Read-Host "Pressione Enter para fechar"
    exit
}

Write-Host ""
Write-Host "Publicando..." -ForegroundColor Yellow

# Add + commit + push
git add .
git commit -m $msg
$pushResult = git push origin main 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  PUBLICADO COM SUCESSO!" -ForegroundColor Green
    Write-Host "  Vercel fara o deploy em ~30 segundos" -ForegroundColor Green
    Write-Host "  jtp-operacional.vercel.app" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "ERRO no push:" -ForegroundColor Red
    Write-Host $pushResult -ForegroundColor Red
    Write-Host ""
    Write-Host "Dica: Se pediu senha, use seu Personal Access Token do GitHub." -ForegroundColor Yellow
}

Write-Host ""
Read-Host "Pressione Enter para fechar"
