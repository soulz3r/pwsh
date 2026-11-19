$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$script:failed = $false

function Assert-Condition {
    param([bool]$Condition,[string]$Message)
    if (-not $Condition) {
        $script:failed = $true
        Write-Host "[FAIL] $Message" -ForegroundColor Red
    } else { Write-Host "[PASS] $Message" -ForegroundColor Green }
}

$files = Get-ChildItem -LiteralPath $root -Filter '*.ps1' -File -Recurse |
    Where-Object { $_.FullName -notmatch '[\\/](\.git|\.github)[\\/]' }
foreach ($file in $files) {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$tokens,[ref]$errors) | Out-Null
    Assert-Condition ($errors.Count -eq 0) "PowerShell syntax: $($file.FullName)"
    foreach ($parseError in $errors) { Write-Host "       $($parseError.Message)" -ForegroundColor Red }
}

$required = @(
    'Microsoft.PowerShell_profile.ps1','install.ps1','zen.toml',
    'conf.d/10-environment.ps1','conf.d/15-readline.ps1','conf.d/20-prompt.ps1',
    'conf.d/30-navigation.ps1','conf.d/40-filesystem.ps1','conf.d/60-fzf.ps1',
    'conf.d/90-silkterm.ps1','docs/design-decisions.md'
)
foreach ($relativePath in $required) {
    Assert-Condition (Test-Path -LiteralPath (Join-Path $root $relativePath) -PathType Leaf) "Required file: $relativePath"
}

if (-not $script:failed) {
    . (Join-Path $root 'Microsoft.PowerShell_profile.ps1')
    . (Join-Path $root 'Microsoft.PowerShell_profile.ps1')
    foreach ($name in @('croot','cproj','mkcd','ff','rdtree','nvg')) {
        Assert-Condition ([bool](Get-Command $name -CommandType Function -ErrorAction SilentlyContinue)) "Profile function: $name"
    }
    Assert-Condition ((Get-Command rmdir -ErrorAction Stop).CommandType -eq 'Alias') 'Built-in rmdir alias remains intact'

    $tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("pwsh-profile-test-" + [guid]::NewGuid())
    $tempDirectory = Join-Path $tempRoot 'delete-me'
    $null = New-Item -ItemType Directory -Path $tempDirectory -Force
    try {
        rdtree -WhatIf $tempDirectory
        Assert-Condition (Test-Path -LiteralPath $tempDirectory -PathType Container) 'rdtree -WhatIf preserves target'
    } finally { Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue }

    # Exercise installer writes against a disposable profile, never the real one.
    $installRoot = Join-Path ([IO.Path]::GetTempPath()) ("pwsh-installer-test-" + [guid]::NewGuid())
    $installProfile = Join-Path $installRoot 'profile.ps1'
    $null = New-Item -ItemType Directory -Path $installRoot -Force
    Set-Content -LiteralPath $installProfile -Value '# existing user content'
    try {
        & (Join-Path $root 'install.ps1') -ProfilePath $installProfile
        $firstInstall = Get-Content -LiteralPath $installProfile -Raw
        Assert-Condition ($firstInstall.Contains('# existing user content') -and $firstInstall.Contains('# >>> soulz3r/pwsh managed profile >>>')) 'Installer preserves existing content and adds managed block'
        & (Join-Path $root 'install.ps1') -ProfilePath $installProfile
        $secondInstall = Get-Content -LiteralPath $installProfile -Raw
        $backups = @(Get-ChildItem -LiteralPath $installRoot -Filter 'profile.ps1.backup-*' -File)
        Assert-Condition ($firstInstall -ceq $secondInstall -and $backups.Count -eq 1) 'Installer is idempotent and backs up only the first change'
    } finally {
        Remove-Item -LiteralPath $installRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    $linkRoot = Join-Path ([IO.Path]::GetTempPath()) ("pwsh-profile-link-" + [guid]::NewGuid())
    $linkPath = Join-Path $linkRoot 'Microsoft.PowerShell_profile.ps1'
    try {
        $null = New-Item -ItemType Directory -Path $linkRoot
        $null = New-Item -ItemType SymbolicLink -Path $linkPath -Target (Join-Path $root 'Microsoft.PowerShell_profile.ps1')
        . $linkPath
        Assert-Condition ([bool](Get-Command croot -CommandType Function -ErrorAction SilentlyContinue)) 'Profile loads through symlink'
    } catch { Write-Warning "Symlink test unavailable in this environment: $($_.Exception.Message)" }
    finally { if (Test-Path -LiteralPath $linkRoot) { Remove-Item -LiteralPath $linkRoot -Recurse -Force } }

    $pwsh = Join-Path $PSHOME 'pwsh.exe'
    if (Test-Path -LiteralPath $pwsh) {
        $profilePath = (Join-Path $root 'Microsoft.PowerShell_profile.ps1').Replace("'","''")
        $childCommand = ". '$profilePath'; if (-not (Get-Command croot -CommandType Function -ErrorAction SilentlyContinue)) { exit 7 }; 'isolated profile OK'"
        $childOutput = & $pwsh -NoLogo -NoProfile -Command $childCommand 2>&1
        Assert-Condition ($LASTEXITCODE -eq 0) "Isolated profile process: $($childOutput -join ' ')"
    }
}

if ($script:failed) { throw 'PowerShell repository validation failed.' }
Write-Host 'All PowerShell checks passed.' -ForegroundColor Green
