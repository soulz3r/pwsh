# Use lsd for familiar listing commands when it is installed.
# Keep native PowerShell listing commands available through Get-ChildItem.

$lsd = Get-Command lsd -CommandType Application -ErrorAction SilentlyContinue
if ($lsd) {
    Set-Alias -Name ls -Value $lsd.Source -Scope Global -Force

    function ll { lsd -l @args }
    function la { lsd -la @args }
    function lt { lsd --tree @args }
}
