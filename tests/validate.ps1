$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$script:failed = $false

function Assert-Condition {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { Write-Host "[PASS] $Message" -ForegroundColor Green }
    else {
        $script:failed = $true
        Write-Host "[FAIL] $Message" -ForegroundColor Red
    }
}

Get-ChildItem -LiteralPath $root -Filter '*.ps1' -File -Recurse |
    Where-Object { $_.FullName -notmatch '[\\/](\.git|\.github)[\\/]' } |
    ForEach-Object {
        $tokens = $null
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile(
            $_.FullName, [ref]$tokens, [ref]$errors
        ) | Out-Null
        Assert-Condition ($errors.Count -eq 0) "Syntax: $($_.Name)"
    }

$themePath = Join-Path $root 'zen.toml'
Assert-Condition (Test-Path -LiteralPath $themePath -PathType Leaf) 'Oh My Posh theme exists'
$theme = Get-Content -LiteralPath $themePath -Raw
Assert-Condition ($theme -match "(?m)^version\s*=\s*4\r?$") 'Oh My Posh theme uses config v4'
Assert-Condition ($theme.Contains("type = 'git'")) 'Prompt includes Git context'
Assert-Condition ($theme.Contains("type = 'vimode'")) 'Prompt includes Vi mode'
Assert-Condition ($theme -match "template = '\{\{ \.Path \}\}'") 'Prompt path is plain text'
Assert-Condition ($theme -notmatch 'leading_diamond|trailing_diamond|powerline_symbol||') 'Prompt has no powerline decoration'
Assert-Condition ($theme -notmatch 'executiontime|battery|sysinfo|spotify') 'Prompt avoids unrelated segments'

$promptSource = Get-Content -LiteralPath (Join-Path $root 'conf.d/20-prompt.ps1') -Raw
Assert-Condition ($promptSource -match '\$ohMyPosh\.Source init pwsh --config') 'Profile initializes Oh My Posh'
Assert-Condition ($promptSource -match '__zoxide_prompt_old') 'Prompt reload restores zoxide wrapper safely'

$toolsSource = Get-Content -LiteralPath (Join-Path $root 'conf.d/40-tools.ps1') -Raw
Assert-Condition ($toolsSource -match 'Get-Command lsd') 'lsd integration is optional'
Assert-Condition ($toolsSource -match 'Set-Alias -Name ls') 'ls uses lsd when installed'

$fzfSource = Get-Content -LiteralPath (Join-Path $root 'conf.d/45-fzf.ps1') -Raw
Assert-Condition ($fzfSource -match '--height=60%') 'fzf uses a compact terminal height'
Assert-Condition ($fzfSource -match '--layout=reverse') 'fzf uses reverse layout'
Assert-Condition ($fzfSource -match '--border=rounded') 'fzf uses a rounded border'

. (Join-Path $root 'Microsoft.PowerShell_profile.ps1')
Assert-Condition ($env:FZF_DEFAULT_OPTS -match '--height=60%') 'Profile applies compact fzf defaults'
Assert-Condition ($env:FZF_DEFAULT_OPTS -match '--border=rounded') 'Profile applies fzf border defaults'

foreach ($name in @('croot', 'mkcd', 'g', 'gs', 'ga', 'gco', 'gcb', 'gcm', 'gpl', 'gps', 'glog', 'v')) {
    Assert-Condition ([bool](Get-Command $name -ErrorAction SilentlyContinue)) "Command: $name"
}
foreach ($name in @('c', 'which', 'vi')) {
    Assert-Condition ([bool](Get-Command $name -CommandType Alias -ErrorAction SilentlyContinue)) "Alias: $name"
}

if ($script:failed) { throw 'PowerShell validation failed.' }
Write-Host 'All PowerShell checks passed.' -ForegroundColor Green
