if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine -ErrorAction SilentlyContinue

    try {
        Set-PSReadLineOption -EditMode Vi
        # Oh My Posh's vimode segment owns the indicator and redraw handler.
        Set-PSReadLineOption -ViModeIndicator Script
        Set-PSReadLineOption -HistorySearchCursorMovesToEnd
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin
        Set-PSReadLineOption -PredictionViewStyle InlineView
        Set-PSReadLineOption -BellStyle None
    } catch {
        Write-Verbose "Some PSReadLine options are unavailable: $($_.Exception.Message)"
    }
}
