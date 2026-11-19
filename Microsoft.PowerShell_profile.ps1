# Personal PowerShell profile entrypoint.
# Keep this file small: add features as focused scripts under conf.d/.
#
# Resolve this file's symlink first. PowerShell may report PSScriptRoot as
# the directory containing the profile symlink (Documents\PowerShell),
# rather than the repository containing the real profile and conf.d/.

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
    Get-ChildItem -LiteralPath $profileModules -Filter '*.ps1' -File |
        Sort-Object Name |
        ForEach-Object {
            . $_.FullName
        }
}
