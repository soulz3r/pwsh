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


# Ctrl+R searches saved PSReadLine history in the compact fzf popup.
$fzf = Get-Command fzf -CommandType Application -ErrorAction SilentlyContinue
if ($fzf -and (Get-Module -ListAvailable -Name PSReadLine)) {
    Set-PSReadLineKeyHandler -Chord Ctrl+r -BriefDescription 'Search command history' -LongDescription 'Search recent PowerShell commands with fzf' -ScriptBlock {
        $historyPath = (Get-PSReadLineOption).HistorySavePath
        $history = @()

        if ($historyPath -and (Test-Path -LiteralPath $historyPath -PathType Leaf)) {
            $history = @(Get-Content -LiteralPath $historyPath -Tail 5000 -ErrorAction SilentlyContinue)
        }

        if ($history.Count -eq 0) {
            $history = @(Get-History | ForEach-Object { $_.CommandLine })
        }

        if ($history.Count -eq 0) {
            return
        }

        $selected = $history |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            & $fzf.Source --tac --no-sort

        if (-not [string]::IsNullOrWhiteSpace($selected)) {
            $line = ''
            $cursor = 0
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, $selected)
        }
    }
}
