# ==========================================
# Oh My Posh
# ==========================================

oh-my-posh init pwsh --config "D:\config\fish\zen.toml" |
Invoke-Expression

# ==========================================
# zoxide
# ==========================================
Invoke-Expression (& {
    zoxide init powershell --cmd cd | Out-String
    })

# ==========================================
# lsd
# ==========================================
Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue

function ls  { lsd @args }
function ll  { lsd -l @args }
function la  { lsd -la @args }
function lt  { lsd --tree @args }
function llt { lsd --tree -L 2 @args }

function nvm { neovide --frame none @args }


function rmdir {Remove-Item -Force -ErrorAction SilentlyContinue @args}

# ==========================================
# PSReadLine
# ==========================================
Import-Module PSReadLine
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle InlineView
Set-PSReadLineOption -BellStyle None

# ==========================================
# PSFzf
# ==========================================
Import-Module PSFzf
# Ctrl+T: fuzzy file and directory search
# Ctrl+R: fuzzy command history search
# Alt+C: fuzzy directory navigation

Set-PsFzfOption `    -PSReadlineChordProvider 'Ctrl+t'`
-PSReadlineChordReverseHistory 'Ctrl+r' `
-PSReadlineChordSetLocation 'Alt+c'

# ==========================================
# fzf
# ==========================================

$env:FZF_DEFAULT_OPTS = @"
--height=40%
--layout=reverse
--border=rounded
--padding=1
--info=inline
--prompt='❯ '
--pointer='▶'
--marker='✓'
"@

# >>> SilkTerm shell integration >>>
# Reports this shell's directory to the terminal, so a new tab, pane or window
# opens where this shell is. PowerShell keeps its location to itself, so there
# is nothing for a terminal to read unless the shell says so. Nothing is drawn
# on screen, and a terminal that does not understand the sequence ignores it.
# It also sets a prompt showing which PowerShell this is - but only when the
# prompt is still the stock one, so your own prompt is never replaced.
# Delete this block to switch it off - SilkTerm will not put it back. It does
# keep the block itself up to date, so an edit made INSIDE the two markers is
# replaced on a later launch - copy it out below them to make it yours.
if ($Host.Name -eq 'ConsoleHost' -and -not [Console]::IsOutputRedirected) {
	function global:__SilkTermReportDir {
		$dir = $ExecutionContext.SessionState.Path.CurrentLocation.ProviderPath
		if ($dir) { Write-Host -NoNewline ("{0}]9;9;`"{1}`"{0}\" -f [char]27, $dir) }
	}
	# Is this still the prompt PowerShell ships? Its own help link is the marker:
	# a prompt anybody has written, or that oh-my-posh or starship installed,
	# will not carry it. Only the stock one is replaced.
	$__SilkTermStock = (-not $function:prompt) -or ($function:prompt.ToString() -match 'LinkID=225750')
	function global:__SilkTermPrompt {
		# "[PS 7.6] C:\some\path\> " - the version, because two PowerShells look
		# alike at a prompt, and a trailing separator so the path reads as one.
		$dir = "$($ExecutionContext.SessionState.Path.CurrentLocation)"
		$sep = [System.IO.Path]::DirectorySeparatorChar
		if (-not ($dir.EndsWith($sep) -or $dir.EndsWith('/'))) { $dir += $sep }
		$v = $PSVersionTable.PSVersion
		"[PS $($v.Major).$($v.Minor)] $dir$('>' * ($NestedPromptLevel + 1)) "
	}
	if ($null -ne $ExecutionContext.SessionState.InvokeCommand.PSObject.Properties['LocationChangedAction']) {
		# PowerShell 6+ can be told about the location itself, which leaves the
		# prompt alone - oh-my-posh, starship and a hand-written prompt all keep
		# working, and anything already using this hook is called first.
		$global:__SilkTermPrevLocation = $ExecutionContext.SessionState.InvokeCommand.LocationChangedAction
		$ExecutionContext.SessionState.InvokeCommand.LocationChangedAction = {
			if ($global:__SilkTermPrevLocation) { & $global:__SilkTermPrevLocation @args }
			__SilkTermReportDir
		}
		if ($__SilkTermStock) { function global:prompt { __SilkTermPrompt } }
	}
	else {
		# Windows PowerShell 5.1 has no such hook, so wrap whatever prompt is in
		# place rather than replacing it.
		$global:__SilkTermPrevPrompt = if ($__SilkTermStock) { $null } else { $function:prompt }
		function global:prompt {
			__SilkTermReportDir
			if ($global:__SilkTermPrevPrompt) { & $global:__SilkTermPrevPrompt }
			else { __SilkTermPrompt }
		}
	}
	__SilkTermReportDir
}
# <<< SilkTerm shell integration <<<
