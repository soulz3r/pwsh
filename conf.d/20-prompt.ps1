# Oh My Posh owns prompt rendering.
# Restore the prompt beneath zoxide before reinitializing OMP on profile reload.
if ($global:__zoxide_hooked -eq 1 -and $global:__zoxide_prompt_old -is [scriptblock]) {
    Set-Item -Path 'Function:global:prompt' -Value $global:__zoxide_prompt_old -Force
    $global:__zoxide_hooked = 0
}

$ohMyPosh = Get-Command oh-my-posh -CommandType Application -ErrorAction SilentlyContinue
$theme = Join-Path $PSScriptRoot '..\\zen.toml'

if (-not $ohMyPosh -or -not (Test-Path -LiteralPath $theme -PathType Leaf)) {
    return
}

try {
    $initScript = & $ohMyPosh.Source init pwsh --config $theme
    if ($LASTEXITCODE -ne 0 -or -not $initScript) {
        throw "Oh My Posh initialization failed (exit code: $LASTEXITCODE)."
    }
    Invoke-Expression ($initScript -join [Environment]::NewLine)
} catch {
    Write-Warning "Oh My Posh initialization failed: $($_.Exception.Message)"
}
