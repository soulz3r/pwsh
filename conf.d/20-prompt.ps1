# Oh My Posh is optional. The theme lives in this repository, not fish.git.
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $theme = Join-Path $PSScriptRoot '..\zen.toml'
    if (Test-Path -LiteralPath $theme -PathType Leaf) {
        oh-my-posh init pwsh --config $theme | Invoke-Expression
    }
}
