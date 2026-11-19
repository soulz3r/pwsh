# Personal PowerShell profile entrypoint.
# Keep this file small: add features as focused scripts under conf.d/.
# Resolve this file's symlink before locating the repository configuration.

$profileFile = Get-Item -LiteralPath $PSCommandPath -Force -ErrorAction Stop
while ($profileFile.LinkType -eq 'SymbolicLink') {
    $target = [string]$profileFile.Target
    if (-not [System.IO.Path]::IsPathRooted($target)) {
        $target = Join-Path $profileFile.DirectoryName $target
    }
    $profileFile = Get-Item -LiteralPath $target -Force -ErrorAction Stop
}

$profileRoot = $profileFile.DirectoryName
$profileModules = Join-Path $profileRoot 'conf.d'

if (Test-Path -LiteralPath $profileModules -PathType Container) {
    $components = Get-ChildItem -LiteralPath $profileModules -Filter '*.ps1' -File |
        Sort-Object -Property Name

    foreach ($component in $components) {
        try {
            . $component.FullName
        } catch {
            Write-Warning "Profile component '$($component.Name)' failed to load: $($_.Exception.Message)"
        }
    }
}
