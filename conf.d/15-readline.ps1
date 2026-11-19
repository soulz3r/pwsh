# PSReadLine owns editing behavior. Oh My Posh owns the live Vi prompt
# indicator when it initializes; Cursor is the safe fallback without OMP.
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine -ErrorAction SilentlyContinue
    try {
        Set-PSReadLineOption -EditMode Vi
        Set-PSReadLineOption -ViModeIndicator Cursor
        Set-PSReadLineOption -HistorySearchCursorMovesToEnd
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin
        Set-PSReadLineOption -PredictionViewStyle InlineView
        Set-PSReadLineOption -BellStyle None
    } catch { Write-Verbose "Some PSReadLine options are unavailable: $($_.Exception.Message)" }
}
