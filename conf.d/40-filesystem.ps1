# lsd is optional; native PowerShell commands remain available as fallbacks.
if (Get-Command lsd -ErrorAction SilentlyContinue) {
    Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
}

function ls  { if (Get-Command lsd -ErrorAction SilentlyContinue) { lsd @args } else { Get-ChildItem @args } }
function ll  { if (Get-Command lsd -ErrorAction SilentlyContinue) { lsd -l @args } else { Get-ChildItem @args | Format-Table -AutoSize } }
function la  { if (Get-Command lsd -ErrorAction SilentlyContinue) { lsd -la @args } else { Get-ChildItem -Force @args } }
function lt  { if (Get-Command lsd -ErrorAction SilentlyContinue) { lsd --tree @args } else { Get-ChildItem -Recurse @args } }
function llt { if (Get-Command lsd -ErrorAction SilentlyContinue) { lsd --tree -L 2 @args } else { Get-ChildItem -Recurse -Depth 2 @args } }

function nvm { neovide --frame none @args }

function rmdir {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [string[]]$Path
    )

    process {
        foreach ($target in $Path) {
            if ($PSCmdlet.ShouldProcess($target, 'Delete directory recursively')) {
                Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction Stop
            }
        }
    }
}
