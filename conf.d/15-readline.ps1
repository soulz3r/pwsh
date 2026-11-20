# Keep editing behavior simple: Vi keys, cursor mode indicator, quiet bell.
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine -ErrorAction SilentlyContinue
    Set-PSReadLineOption -EditMode Vi
    Set-PSReadLineOption -ViModeIndicator Cursor
    Set-PSReadLineOption -BellStyle None
}
