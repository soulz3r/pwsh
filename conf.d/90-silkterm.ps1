# >>> SilkTerm shell integration >>>
# Keep the location callback single-installed, but refresh the prompt wrapper
# after profile reloads (20-prompt and zoxide can recreate prompt first).
if ($Host.Name -eq 'ConsoleHost' -and -not [Console]::IsOutputRedirected) {
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

    $locationChangedProperty = $ExecutionContext.SessionState.InvokeCommand.PSObject.Properties['LocationChangedAction']

    if ($null -ne $locationChangedProperty) {
        if (-not $global:__SilkTermLocationHookInstalled) {
            $global:__SilkTermPrevLocation = $ExecutionContext.SessionState.InvokeCommand.LocationChangedAction
            $ExecutionContext.SessionState.InvokeCommand.LocationChangedAction = {
                if ($global:__SilkTermPrevLocation) {
                    & $global:__SilkTermPrevLocation @args
                }
                __SilkTermReportDir
            }
            $global:__SilkTermLocationHookInstalled = $true
        }

        if ($__SilkTermStock) {
            function global:prompt { __SilkTermPrompt }
        }
    } else {
        $currentPrompt = $function:prompt
        $alreadyWrapped = $null -ne $currentPrompt -and
            $currentPrompt.ToString().Contains('__SilkTermReportDir')

        if (-not $alreadyWrapped) {
            $global:__SilkTermPrevPrompt = if ($__SilkTermStock) { $null } else { $currentPrompt }

            function global:prompt {
                __SilkTermReportDir
                if ($global:__SilkTermPrevPrompt) {
                    & $global:__SilkTermPrevPrompt
                } else {
                    __SilkTermPrompt
                }
            }
        }
    }

    __SilkTermReportDir
}
# <<< SilkTerm shell integration <<<
