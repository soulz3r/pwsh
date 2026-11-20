# Keep fzf inside the terminal instead of switching to a full-screen interface.
# Respect existing user options; only provide defaults for missing layout settings.

$fzfOptions = [System.Collections.Generic.List[string]]::new()
if (-not [string]::IsNullOrWhiteSpace($env:FZF_DEFAULT_OPTS)) {
    $fzfOptions.Add($env:FZF_DEFAULT_OPTS.Trim())
}

foreach ($option in @(
    @{ Name = 'height'; Value = '--height=60%' },
    @{ Name = 'layout'; Value = '--layout=reverse' },
    @{ Name = 'border'; Value = '--border=rounded' },
    @{ Name = 'info'; Value = '--info=inline' },
    @{ Name = 'margin'; Value = '--margin=1' },
    @{ Name = 'padding'; Value = '--padding=1' }
)) {
    if ($env:FZF_DEFAULT_OPTS -notmatch "(?<!\S)--$($option.Name)(?:=|\s|$)") {
        $fzfOptions.Add($option.Value)
    }
}

$env:FZF_DEFAULT_OPTS = $fzfOptions -join ' '
