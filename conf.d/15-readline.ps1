# PSReadLine owns editing behavior. Oh My Posh's vimode segment installs
# the live mode-change handler during prompt initialization.
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine -ErrorAction SilentlyContinue

    $options = @(
        @{ EditMode = 'Vi' }
        @{ ViModeIndicator = 'Script' }
        @{ HistorySearchCursorMovesToEnd = $true }
        @{ PredictionSource = 'HistoryAndPlugin' }
        @{ PredictionViewStyle = 'InlineView' }
        @{ BellStyle = 'None' }
    )

    foreach ($option in $options) {
        try {
            Set-PSReadLineOption @option
        } catch {
            Write-Verbose "PSReadLine option '$($option.Keys -join ', ')' is unavailable: $($_.Exception.Message)"
        }
    }
}
