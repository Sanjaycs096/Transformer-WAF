Write-Host "=== PRE-COMMIT VERIFICATION ===" 
Write-Host ""

# 1. Check Git
if (Test-Path .git) {
    Write-Host "[OK] Git repository initialized"
} else {
    Write-Host "[WARN] Git not initialized - run: git init"
    exit 1
}

# 2. Verify .gitignore patterns
Write-Host ""
Write-Host "Checking .gitignore patterns..."
$required = @("node_modules/", "venv/", "__pycache__/", "*.pyc", "models/", "*.pt", "*.log")
$missing = @()

foreach ($pattern in $required) {
    if (Select-String -Path .gitignore -Pattern ([regex]::Escape($pattern)) -Quiet) {
        Write-Host "  [OK] $pattern"
    } else {
        Write-Host "  [MISSING] $pattern"
        $missing += $pattern
    }
}

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "[ERROR] Missing patterns in .gitignore: $($missing -join ', ')"
    exit 1
}

# 3. Check for accidentally tracked large directories
Write-Host ""
Write-Host "Checking for large directories..."
git add -A 2>&1 | Out-Null
$tracked = git ls-files 2>&1

if ($tracked -match "node_modules") {
    Write-Host "  [ERROR] node_modules is being tracked!"
    exit 1
}
if ($tracked -match "venv/") {
    Write-Host "  [ERROR] venv is being tracked!"
    exit 1
}
Write-Host "  [OK] No large directories in staging"

# 4. Summary
Write-Host ""
Write-Host "=== READY TO COMMIT ===" 
$count = ($tracked | Measure-Object).Count
Write-Host "Files to commit: $count"
Write-Host ""
Write-Host "Next steps:"
Write-Host '  git commit -m "Initial commit: Transformer WAF with supervised classification"'
Write-Host '  git branch -M main'
Write-Host '  git remote add origin <your-repo-url>'
Write-Host '  git push -u origin main'
