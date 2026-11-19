# Oh My Posh owns prompt rendering and the live PSReadLine Vi-mode hook.
# If it cannot initialize, restore PSReadLine's visible cursor indicator.

# A profile reload runs this component before zoxide. Restore the prompt that
# zoxide wrapped last time so its next initialization never wraps itself.
if ($global:__zoxide_hooked -eq 1 -and $global:__zoxide_prompt_old -is [scriptblock]) {
    Set-Item -Path 'Function:global:prompt' -Value $global:__zoxide_prompt_old -Force
    $global:__zoxide_hooked = 0
}
$ohMyPosh = Get-Command oh-my-posh -CommandType Application -ErrorAction SilentlyContinue
$theme = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\zen.toml'))

if (-not $ohMyPosh -or -not (Test-Path -LiteralPath $theme -PathType Leaf)) {
    try { Set-PSReadLineOption -ViModeIndicator Cursor -ErrorAction Stop } catch {}
    return
}

try {
    $initScript = & $ohMyPosh.Source init pwsh --config $theme
    if ($LASTEXITCODE -ne 0 -or -not $initScript) {
        throw "Oh My Posh did not return a PowerShell initialization script (exit code: $LASTEXITCODE)."
    }

    Invoke-Expression ($initScript -join [Environment]::NewLine)
} catch {
    try { Set-PSReadLineOption -ViModeIndicator Cursor -ErrorAction Stop } catch {}
    Write-Warning "Oh My Posh initialization failed: $($_.Exception.Message)"
}
