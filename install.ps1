# Register this repository as the current user's PowerShell profile.
param([string]$ProfilePath = $PROFILE)

$ErrorActionPreference = 'Stop'
$repoProfile = Join-Path $PSScriptRoot 'Microsoft.PowerShell_profile.ps1'

if (-not (Test-Path -LiteralPath $repoProfile -PathType Leaf)) {
    throw "Repository profile not found: $repoProfile"
}
if (Test-Path -LiteralPath $ProfilePath -PathType Container) {
    throw "Profile path is a directory: $ProfilePath"
}

$existing = Get-Item -LiteralPath $ProfilePath -Force -ErrorAction SilentlyContinue
if ($existing -and $existing.LinkType -eq 'SymbolicLink') {
    $resolved = (Resolve-Path -LiteralPath $ProfilePath -ErrorAction Stop).ProviderPath
    $target = (Resolve-Path -LiteralPath $repoProfile).ProviderPath
    if ($resolved -eq $target) {
        Write-Host 'Profile already points to this repository.'
        return
    }
    throw "Refusing to write through existing symbolic link: $ProfilePath"
}

$directory = Split-Path -Parent $ProfilePath
New-Item -ItemType Directory -Path $directory -Force | Out-Null
$escaped = $repoProfile.Replace("'", "''")
$block = @"
# >>> soulz3r/pwsh >>>
. '$escaped'
# <<< soulz3r/pwsh <<<
"@

if (Test-Path -LiteralPath $ProfilePath -PathType Leaf) {
    $content = Get-Content -LiteralPath $ProfilePath -Raw
    $start = '# >>> soulz3r/pwsh >>>'
    $end = '# <<< soulz3r/pwsh <<<'
    $startAt = $content.IndexOf($start, [StringComparison]::Ordinal)
    $endAt = $content.IndexOf($end, [StringComparison]::Ordinal)

    if (($startAt -ge 0) -xor ($endAt -ge 0) -or ($endAt -ge 0 -and $endAt -lt $startAt)) {
        throw 'Profile markers are incomplete or out of order.'
    }

    if ($startAt -ge 0) {
        $updated = $content.Substring(0, $startAt) + $block + $content.Substring($endAt + $end.Length)
    } else {
        $updated = $content + [Environment]::NewLine + $block + [Environment]::NewLine
    }

    if ($updated -cne $content) {
        Copy-Item -LiteralPath $ProfilePath -Destination "$ProfilePath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Set-Content -LiteralPath $ProfilePath -Value $updated -Encoding utf8NoBOM
    }
} else {
    Set-Content -LiteralPath $ProfilePath -Value $block -Encoding utf8NoBOM
}

Write-Host "Registered profile: $ProfilePath"
