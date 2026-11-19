# Personal PowerShell profile entrypoint.
# Keep this file small: add features as focused scripts under conf.d/.

$profileRoot = $PSScriptRoot
$profileModules = Join-Path $profileRoot 'conf.d'

if (Test-Path -LiteralPath $profileModules -PathType Container) {
    Get-ChildItem -LiteralPath $profileModules -Filter '*.ps1' -File |
        Sort-Object Name |
        ForEach-Object {
            . $_.FullName
        }
}
