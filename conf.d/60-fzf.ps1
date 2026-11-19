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
    if ($existingOptions -notmatch "(?<!\S)$([regex]::Escape($name))(?:=|\s|$)") {
        $option
    }
}

if ($missingOptions) {
    $parts = @($existingOptions, ($missingOptions -join ' ')) |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    $env:FZF_DEFAULT_OPTS = $parts -join ' '
}

# PSFzf is optional and may already be loaded by another profile component.
if (Get-Module -ListAvailable -Name PSFzf) {
    try {
        if (-not (Get-Module -Name PSFzf)) {
            Import-Module PSFzf -ErrorAction Stop
        }

        if (Get-Command Set-PsFzfOption -ErrorAction SilentlyContinue) {
            Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r' -PSReadlineChordSetLocation 'Alt+c'
        }
    } catch {
        Write-Warning "PSFzf integration could not be initialized: $($_.Exception.Message)"
    }
}
