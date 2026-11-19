# Register this repository as the current user's PowerShell profile.
# Safe to run repeatedly. Existing profile content is preserved.

$ErrorActionPreference = 'Stop'

$repoProfile = Join-Path $PSScriptRoot 'Microsoft.PowerShell_profile.ps1'
$theme = Join-Path $PSScriptRoot 'zen.toml'
$targetProfile = $PROFILE

if (-not (Test-Path -LiteralPath $repoProfile -PathType Leaf)) {
    throw "Repository profile not found: $repoProfile"
}

if (-not (Test-Path -LiteralPath $theme -PathType Leaf)) {
    throw "Oh My Posh theme not found: $theme"
}

$profileDirectory = Split-Path -Parent $targetProfile
New-Item -ItemType Directory -Path $profileDirectory -Force | Out-Null

$startMarker = '# >>> soulz3r/pwsh managed profile >>>'
$endMarker = '# <<< soulz3r/pwsh managed profile <<<'
$escapedProfile = $repoProfile.Replace("'", "''")

$managedBlock = @"
$startMarker
. '$escapedProfile'
$endMarker
"@

if (Test-Path -LiteralPath $targetProfile -PathType Leaf) {
    $original = Get-Content -LiteralPath $targetProfile -Raw
} else {
    $original = ''
}

$startIndex = $original.IndexOf($startMarker, [StringComparison]::Ordinal)
$endIndex = $original.IndexOf($endMarker, [StringComparison]::Ordinal)

if (($startIndex -ge 0) -xor ($endIndex -ge 0)) {
    throw "The managed profile markers are incomplete in '$targetProfile'. Repair that block before reinstalling."
}

if ($startIndex -ge 0) {
    if ($endIndex -lt $startIndex) {
        throw "The managed profile markers are out of order in '$targetProfile'."
    }

    $endIndex += $endMarker.Length
    $updated = $original.Substring(0, $startIndex) +
        $managedBlock +
        $original.Substring($endIndex)
} else {
    $separator = if ($original.Length -gt 0 -and $original -notmatch '[\r\n]$') {
        [Environment]::NewLine
    } else {
        ''
    }

    $updated = $original + $separator + $managedBlock + [Environment]::NewLine
}

if ($updated -cne $original) {
    if (Test-Path -LiteralPath $targetProfile -PathType Leaf) {
        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $backupPath = "$targetProfile.backup-$stamp"
        Copy-Item -LiteralPath $targetProfile -Destination $backupPath
        Write-Host "Backed up existing profile: $backupPath" -ForegroundColor DarkGray
    }

    Set-Content -LiteralPath $targetProfile -Value $updated -Encoding utf8NoBOM
    Write-Host "Registered repository profile in: $targetProfile" -ForegroundColor Green
} else {
    Write-Host 'Repository profile is already registered.' -ForegroundColor Green
}

if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    Write-Warning 'Oh My Posh is not on PATH. Install it before expecting the custom prompt to appear.'
} else {
    Write-Host 'Oh My Posh was found.' -ForegroundColor Green
}

Write-Host 'Restart PowerShell to load the repository prompt by default.' -ForegroundColor Cyan
