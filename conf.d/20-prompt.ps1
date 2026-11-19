# Oh My Posh owns prompt rendering and its live Vi-mode callback.
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $theme = Join-Path $PSScriptRoot '..\zen.toml'
    if (Test-Path -LiteralPath $theme -PathType Leaf) {
        try { oh-my-posh init pwsh --config $theme | Invoke-Expression }
        catch { Write-Warning "Oh My Posh initialization failed: $($_.Exception.Message)" }
    }
}
