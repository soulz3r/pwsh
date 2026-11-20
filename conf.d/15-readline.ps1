# PSReadLine handles Vi editing; Oh My Posh handles the live mode display.
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine -ErrorAction SilentlyContinue
    Set-PSReadLineOption -EditMode Vi
    Set-PSReadLineOption -ViModeIndicator Script
    Set-PSReadLineOption -BellStyle None
}
