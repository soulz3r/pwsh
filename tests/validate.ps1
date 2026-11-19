$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$failed = $false

$files = @(
    Get-ChildItem -LiteralPath $root -Filter '*.ps1' -File -Recurse |
        Where-Object { $_.FullName -notmatch '[\\/](\.git|\.github)[\\/]' }
)

foreach ($file in $files) {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile(
        $file.FullName,
        [ref]$tokens,
        [ref]$errors
    ) | Out-Null

    if ($errors.Count -gt 0) {
        $failed = $true
        Write-Host "[FAIL] $($file.FullName)" -ForegroundColor Red
        foreach ($errorItem in $errors) {
            Write-Host "       $($errorItem.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "[PASS] $($file.Name)" -ForegroundColor Green
    }
}

$required = @(
    'Microsoft.PowerShell_profile.ps1',
    'zen.toml',
    'conf.d/10-environment.ps1',
    'conf.d/20-prompt.ps1',
    'conf.d/30-navigation.ps1',
    'conf.d/40-filesystem.ps1',
    'conf.d/50-readline.ps1',
    'conf.d/60-fzf.ps1',
    'conf.d/90-silkterm.ps1'
)

foreach ($relativePath in $required) {
    $fullPath = Join-Path $root $relativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        $failed = $true
        Write-Host "[FAIL] Missing $relativePath" -ForegroundColor Red
    }
}

if (-not $failed) {
    # Dot-source in a clean process in CI to verify the loader defines core commands.
    . (Join-Path $root 'Microsoft.PowerShell_profile.ps1')
    foreach ($commandName in 'croot', 'cproj', 'mkcd', 'ff', 'rmdir') {
        if (-not (Get-Command $commandName -CommandType Function -ErrorAction SilentlyContinue)) {
            $failed = $true
            Write-Host "[FAIL] Missing function $commandName" -ForegroundColor Red
        } else {
            Write-Host "[PASS] Function $commandName" -ForegroundColor Green
        }
    }
}

if ($failed) {
    throw 'PowerShell repository validation failed.'
}

Write-Host 'All PowerShell checks passed.' -ForegroundColor Green
