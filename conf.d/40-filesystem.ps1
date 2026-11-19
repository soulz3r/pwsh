# lsd is optional; native PowerShell commands remain available as fallbacks.
# Remove the built-in ls alias even without lsd, otherwise it shadows our function.
Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue

function ls { if (Get-Command lsd -ErrorAction SilentlyContinue) { lsd @args } else { Get-ChildItem @args } }
function ll { if (Get-Command lsd -ErrorAction SilentlyContinue) { lsd -l @args } else { Get-ChildItem @args | Format-Table -AutoSize } }
function la { if (Get-Command lsd -ErrorAction SilentlyContinue) { lsd -la @args } else { Get-ChildItem -Force @args } }

function Show-PwshTree {
    param([Parameter(Mandatory)][string]$Path,[int]$MaxDepth = 3,[int]$CurrentDepth = 0)
    if ($CurrentDepth -ge $MaxDepth) { return }
    Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue |
        Sort-Object @{ Expression = 'PSIsContainer'; Descending = $true }, Name |
        ForEach-Object {
            $indent = '  ' * $CurrentDepth
            $suffix = if ($_.PSIsContainer) { [IO.Path]::DirectorySeparatorChar } else { '' }
            Write-Output "$indent$($_.Name)$suffix"
            if ($_.PSIsContainer -and -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
                Show-PwshTree -Path $_.FullName -MaxDepth $MaxDepth -CurrentDepth ($CurrentDepth + 1)
            }
        }
}

function lt {
    [CmdletBinding()] param([string]$Path = '.',[int]$Depth = 5)
    if (Get-Command lsd -ErrorAction SilentlyContinue) { lsd --tree --depth $Depth $Path }
    else { Show-PwshTree -Path $Path -MaxDepth $Depth }
}
function llt { [CmdletBinding()] param([string]$Path = '.'); lt -Path $Path -Depth 2 }

# Use an unambiguous name; nvm conventionally means Node Version Manager.
function nvg { neovide --frame none @args }

# Preserve PowerShell's built-in rmdir alias. Recursive forced deletion is explicit.
function rdtree {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param([Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)][Alias('FullName')][string[]]$Path)
    process {
        foreach ($target in $Path) {
            if (-not (Test-Path -LiteralPath $target -PathType Container)) { throw "Directory does not exist: $target" }
            if ($PSCmdlet.ShouldProcess($target, 'Delete directory recursively and forcefully')) {
                Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction Stop
            }
        }
    }
}
