# Register this repository as the current user's PowerShell profile.
# Safe to run repeatedly. Existing profile content is preserved.
# Existing profile symlinks are never modified.

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

# Many setups link $PROFILE directly to this repository's entrypoint.
# In that arrangement the profile is already installed. Writing a managed
# block through the symlink would make the entrypoint source itself forever.
if (Test-Path -LiteralPath $targetProfile -PathType Leaf) {
    $profileItem = Get-Item -LiteralPath $targetProfile -Force
    $resolvedTarget = (Resolve-Path -LiteralPath $targetProfile).ProviderPath
    $resolvedRepoProfile = (Resolve-Path -LiteralPath $repoProfile).ProviderPath

    if ([string]::Equals(
        $resolvedTarget,
        $resolvedRepoProfile,
        [StringComparison]::OrdinalIgnoreCase
    )) {
        Write-Host 'PowerShell profile already points to this repository. Leaving the symlink untouched.' -ForegroundColor Green
    } elseif ($profileItem.LinkType) {
        throw "The PowerShell profile is a $($profileItem.LinkType) pointing to '$resolvedTarget'. The installer will not write through an existing link. Point it to '$repoProfile' or remove the link before using this installer."
    } else {
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

        $original = Get-Content -LiteralPath $targetProfile -Raw
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
            $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
            $backupPath = "$targetProfile.backup-$stamp"
            Copy-Item -LiteralPath $targetProfile -Destination $backupPath
            Write-Host "Backed up existing profile: $backupPath" -ForegroundColor DarkGray

            Set-Content -LiteralPath $targetProfile -Value $updated -Encoding utf8NoBOM
            Write-Host "Registered repository profile in: $targetProfile" -ForegroundColor Green
        } else {
            Write-Host 'Repository profile is already registered.' -ForegroundColor Green
        }
    }
} else {
    $profileDirectory = Split-Path -Parent $targetProfile
    New-Item -ItemType Directory -Path $profileDirectory -Force | Out-Null

    $escapedProfile = $repoProfile.Replace("'", "''")
    $managedBlock = @"
# >>> soulz3r/pwsh managed profile >>>
. '$escapedProfile'
# <<< soulz3r/pwsh managed profile <<<
"@

    Set-Content -LiteralPath $targetProfile -Value $managedBlock -Encoding utf8NoBOM
    Write-Host "Registered repository profile in: $targetProfile" -ForegroundColor Green
}

if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    Write-Warning 'Oh My Posh is not on PATH. Install it before expecting the custom prompt to appear.'
} else {
    Write-Host 'Oh My Posh was found.' -ForegroundColor Green
}

Write-Host 'Restart PowerShell to load the repository prompt by default.' -ForegroundColor Cyan
