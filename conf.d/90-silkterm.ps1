# >>> SilkTerm shell integration >>>
# Idempotent: re-sourcing the profile must not wrap callbacks repeatedly.
if ($Host.Name -eq 'ConsoleHost' -and -not [Console]::IsOutputRedirected -and -not $global:__SilkTermInstalled) {
    function global:__SilkTermReportDir {
        $dir = $ExecutionContext.SessionState.Path.CurrentLocation.ProviderPath
        if ($dir) {
            $sequence = [char]27 + ']9;9;' + [char]34 + $dir + [char]34 + [char]27 + '\'
            Write-Host -NoNewline $sequence
        }
    }
    $__SilkTermStock = (-not $function:prompt) -or ($function:prompt.ToString() -match 'LinkID=225750')
    function global:__SilkTermPrompt {
        $dir = "$($ExecutionContext.SessionState.Path.CurrentLocation)"
        $sep = [IO.Path]::DirectorySeparatorChar
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
            if ($global:__SilkTermPrevPrompt) { & $global:__SilkTermPrevPrompt } else { __SilkTermPrompt }
        }
    }
    __SilkTermReportDir
    $global:__SilkTermInstalled = $true
}
# <<< SilkTerm shell integration <<<
