Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  HomeStock Git Repair and Auto-Healing Utility" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

Set-Location -Path $PSScriptRoot

Write-Host "[1/4] Checking for and removing stale Git lock files..." -ForegroundColor Yellow
$lockFiles = Get-ChildItem -Path ".git" -Filter "*.lock" -Recurse -Force -ErrorAction SilentlyContinue
foreach ($f in $lockFiles) {
    Write-Host "Removing stale lock: $($f.FullName)" -ForegroundColor Red
    Remove-Item -Path $f.FullName -Force -ErrorAction SilentlyContinue
}

Write-Host "[2/4] Inspecting .git\index health..." -ForegroundColor Yellow
if (Test-Path ".git\index") {
    $indexItem = Get-Item ".git\index"
    Write-Host "Current .git\index size: $($indexItem.Length) bytes" -ForegroundColor Gray
    if ($indexItem.Length -lt 12) {
        Write-Host "[WARNING] .git\index is smaller than expected ($($indexItem.Length) bytes). Rebuilding from HEAD..." -ForegroundColor Magenta
        Remove-Item -Path ".git\index" -Force
        git reset
        Write-Host "Index reconstructed successfully." -ForegroundColor Green
    } else {
        Write-Host "Index file size is healthy." -ForegroundColor Green
    }
} else {
    Write-Host "No index file found. Rebuilding..." -ForegroundColor Magenta
    git reset
}

Write-Host "[3/4] Applying Windows Git performance and anti-corruption settings..." -ForegroundColor Yellow
git config core.preloadindex true
git config core.trustctime false
git config core.fscache true
git config core.untrackedCache true

Write-Host "[4/4] Verifying Git status..." -ForegroundColor Yellow
git status -s

Write-Host ""
Write-Host "========================================================" -ForegroundColor Green
Write-Host "  Git repository is healthy and ready!" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
