$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$script:failed = $false

function Assert-Condition {
    param([bool]$Condition, [string]$Message)
    if ($Condition) {
        Write-Host "[PASS] $Message" -ForegroundColor Green
    } else {
        $script:failed = $true
        Write-Host "[FAIL] $Message" -ForegroundColor Red
    }
}

$files = Get-ChildItem -LiteralPath $root -Filter '*.ps1' -File -Recurse |
    Where-Object { $_.FullName -notmatch '[\\/](\.git|\.github)[\\/]' }

foreach ($file in $files) {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile(
        $file.FullName, [ref]$tokens, [ref]$errors
    ) | Out-Null
    Assert-Condition ($errors.Count -eq 0) "Syntax: $($file.FullName)"
}

. (Join-Path $root 'Microsoft.PowerShell_profile.ps1')

foreach ($name in @('prompt', 'croot', 'up', 'mkcd', 'll', 'la', 'touch', 'g', 'gs', 'ga', 'gco', 'gcb', 'gcm', 'gpl', 'gps', 'glog', 'v', 'nvg')) {
    Assert-Condition ([bool](Get-Command $name -CommandType Function -ErrorAction SilentlyContinue)) "Function: $name"
}

foreach ($name in @('c', 'h', 'which')) {
    Assert-Condition ([bool](Get-Command $name -CommandType Alias -ErrorAction SilentlyContinue)) "Alias: $name"
}

$promptText = (Get-Command prompt).ScriptBlock.ToString()
Assert-Condition ($promptText -match 'Get-Location' -and $promptText -notmatch 'oh-my-posh|git status|zoxide') 'Prompt stays plain and does no external work'

if ($script:failed) {
    throw 'PowerShell validation failed.'
}

Write-Host 'All PowerShell checks passed.' -ForegroundColor Green
