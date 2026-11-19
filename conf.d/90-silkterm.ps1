# >>> SilkTerm shell integration >>>
# Reports this shell's directory to the terminal, so a new tab, pane or window
# opens where this shell is. PowerShell keeps its location to itself, so there
# is nothing for a terminal to read unless the shell says so. Nothing is drawn
# on screen, and a terminal that does not understand the sequence ignores it.
# It also sets a prompt showing which PowerShell this is - but only when the
# prompt is still the stock one, so your own prompt is never replaced.
# Delete this block to switch it off - SilkTerm will not put it back. It does
# keep the block itself up to date - copy edits outside these markers to keep them.
if ($Host.Name -eq 'ConsoleHost' -and -not [Console]::IsOutputRedirected) {
    function global:__SilkTermReportDir {
        $dir = $ExecutionContext.SessionState.Path.CurrentLocation.ProviderPath
        if ($dir) { Write-Host -NoNewline ("{0}]9;9;`"{1}`"{0}\\" -f [char]27, $dir) }
    }

    $__SilkTermStock = (-not $function:prompt) -or ($function:prompt.ToString() -match 'LinkID=225750')

    function global:__SilkTermPrompt {
        $dir = "$($ExecutionContext.SessionState.Path.CurrentLocation)"
        $sep = [System.IO.Path]::DirectorySeparatorChar
        if (-not ($dir.EndsWith($sep) -or $dir.EndsWith('/'))) { $dir += $sep }
        $v = $PSVersionTable.PSVersion
        "[PS $($v.Major).$($v.Minor)] $dir$('>' * ($NestedPromptLevel + 1)) "
    }

    if ($null -ne $ExecutionContext.SessionState.InvokeCommand.PSObject.Properties['LocationChangedAction']) {
        $global:__SilkTermPrevLocation = $ExecutionContext.SessionState.InvokeCommand.LocationChangedAction
        $ExecutionContext.SessionState.InvokeCommand.LocationChangedAction = {
            if ($global:__SilkTermPrevLocation) { & $global:__SilkTermPrevLocation @args }
            __SilkTermReportDir
        }
        if ($__SilkTermStock) { function global:prompt { __SilkTermPrompt } }
    } else {
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
