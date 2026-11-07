# ═══════════════════════════════════════════════════════════
#  push-to-github.ps1
#  Pushes the entire 101 project to GitHub via REST API
#  Run this in PowerShell after setting your token below
# ═══════════════════════════════════════════════════════════

# ── CONFIGURATION ───────────────────────────────────────────
$TOKEN  = "PASTE_YOUR_GITHUB_TOKEN_HERE"   # <-- put your PAT here
$OWNER  = "deborahgeoffreymkamilo-hue"
$REPO   = "Trading-motives"
$BRANCH = "main"
$FOLDER = "$PSScriptRoot"   # folder where this script lives

# ── HEADERS ─────────────────────────────────────────────────
$headers = @{
  "Authorization" = "token $TOKEN"
  "User-Agent"    = "101-push-script"
  "Accept"        = "application/vnd.github.v3+json"
}

# ── INITIALIZE REPO (create first commit if empty) ──────────
Write-Host "Checking repository..." -ForegroundColor Cyan

$refsUrl = "https://api.github.com/repos/$OWNER/$REPO/git/refs"
try {
  $refs = Invoke-RestMethod -Uri $refsUrl -Headers $headers -Method Get
  Write-Host "Repository has commits. Fetching HEAD SHA..." -ForegroundColor Green
  $headSha = $refs[0].object.sha
} catch {
  Write-Host "Repository is empty. Creating initial commit..." -ForegroundColor Yellow
  $headSha = $null
}

# ── FUNCTION: Upload a single file ──────────────────────────
function Push-File {
  param([string]$localPath, [string]$repoPath)

  $bytes   = [System.IO.File]::ReadAllBytes($localPath)
  $b64     = [Convert]::ToBase64String($bytes)
  $apiUrl  = "https://api.github.com/repos/$OWNER/$REPO/contents/$repoPath"

  # Check if file already exists (to get its SHA for update)
  $existingSha = $null
  try {
    $existing    = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
    $existingSha = $existing.sha
  } catch { }

  $body = @{
    message = "Add $repoPath"
    content = $b64
    branch  = $BRANCH
  }
  if ($existingSha) { $body.sha = $existingSha }

  $bodyJson = $body | ConvertTo-Json -Depth 3

  try {
    Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Put -Body $bodyJson -ContentType "application/json" | Out-Null
    Write-Host "  ✓ $repoPath" -ForegroundColor Green
  } catch {
    Write-Host "  ✗ $repoPath — $($_.Exception.Message)" -ForegroundColor Red
  }
}

# ── PUSH ALL FILES ───────────────────────────────────────────
Write-Host ""
Write-Host "Pushing files to github.com/$OWNER/$REPO ..." -ForegroundColor Cyan
Write-Host ""

# index.html
Push-File "$FOLDER\index.html" "index.html"

# README.md
Push-File "$FOLDER\README.md" "README.md"

# All images
$imgFolder = "$FOLDER\images"
Get-ChildItem -Path $imgFolder -File | ForEach-Object {
  Push-File $_.FullName "images/$($_.Name)"
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  DONE! View your project at:" -ForegroundColor Green
Write-Host "  https://github.com/$OWNER/$REPO" -ForegroundColor White
Write-Host ""
Write-Host "  Live site (GitHub Pages — enable in settings):" -ForegroundColor Green
Write-Host "  https://$OWNER.github.io/$REPO" -ForegroundColor White
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan
