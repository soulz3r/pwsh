# Keep PSReadLine on its default Windows editing mode.
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine -ErrorAction SilentlyContinue
    Set-PSReadLineOption -BellStyle None
}
