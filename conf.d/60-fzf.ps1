# Preserve user options and append only defaults that are not already configured.
$fzfDefaults = @(
    '--height=40%'
    '--layout=reverse'
    '--border=rounded'
    '--padding=1'
    '--info=inline'
    "--prompt='❯ '"
    "--pointer='▶'"
    "--marker='✓'"
)
$existingOptions = $env:FZF_DEFAULT_OPTS
$missingOptions = foreach ($option in $fzfDefaults) {
    $name = ($option -split '=', 2)[0]
    if ($existingOptions -notmatch "(?<!\S)$([regex]::Escape($name))(?:=|\s|$)") { $option }
}
if ($missingOptions) {
    $env:FZF_DEFAULT_OPTS = (@($existingOptions, ($missingOptions -join ' ')) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join ' '
}

if (Get-Module -ListAvailable -Name PSFzf) {
    Import-Module PSFzf -ErrorAction SilentlyContinue
    if (Get-Command Set-PsFzfOption -ErrorAction SilentlyContinue) {
        Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r' -PSReadlineChordSetLocation 'Alt+c'
    }
}
