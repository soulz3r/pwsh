# lsd is optional. Keep native PowerShell implementations available.
# Remove the built-in alias unconditionally so it cannot shadow our ls function.
Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue

function Get-PwshLsd {
    Get-Command lsd -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1
}

function ls {
    $lsd = Get-PwshLsd
    if ($lsd) { & $lsd.Source @args }
    else { Get-ChildItem @args }
}

function ll {
    $lsd = Get-PwshLsd
    if ($lsd) { & $lsd.Source -l @args }
    else { Get-ChildItem @args | Format-Table -AutoSize }
}

function la {
    $lsd = Get-PwshLsd
    if ($lsd) { & $lsd.Source -la @args }
    else { Get-ChildItem -Force @args }
}

function Show-PwshTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [ValidateRange(1, 20)][int]$MaxDepth = 5,
        [int]$CurrentDepth = 0,
        [string]$Prefix = ''
    )

    if ($CurrentDepth -ge $MaxDepth) {
        return
    }

    $excluded = @(
        '.git', 'node_modules', '.venv', 'venv', 'bin', 'obj',
        'build', 'dist', 'target', '.cache'
    )
    $entries = @(
        Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue |
            Where-Object {
                -not ($_.PSIsContainer -and $_.Name -in $excluded)
            } |
            Sort-Object @{ Expression = 'PSIsContainer'; Descending = $true }, Name
    )

    for ($index = 0; $index -lt $entries.Count; $index++) {
        $entry = $entries[$index]
        $isLast = $index -eq ($entries.Count - 1)
        $branch = if ($isLast) { '└──' } else { '├──' }
        $suffix = if ($entry.PSIsContainer) { [System.IO.Path]::DirectorySeparatorChar } else { '' }

        Write-Output "$Prefix$branch $($entry.Name)$suffix"

        if ($entry.PSIsContainer -and
            $CurrentDepth + 1 -lt $MaxDepth -and
            -not ($entry.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
            $nextPrefix = if ($isLast) { "$Prefix    " } else { "$Prefix│   " }
            Show-PwshTree -Path $entry.FullName -MaxDepth $MaxDepth -CurrentDepth ($CurrentDepth + 1) -Prefix $nextPrefix
        }
    }
}

function lt {
    [CmdletBinding()]
    param(
        [string]$Path = '.',
        [ValidateRange(1, 20)][int]$Depth = 5
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "Tree root does not exist: $Path"
    }

    $root = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).ProviderPath
    $lsd = Get-PwshLsd

    if ($lsd) {
        $arguments = @('--tree', '--depth', "$Depth")
        foreach ($name in @(
            '.git', 'node_modules', '.venv', 'venv', 'bin',
            'obj', 'build', 'dist', 'target', '.cache'
        )) {
            $arguments += @('--ignore-glob', $name)
        }
        $arguments += $root
        & $lsd.Source @arguments
        return
    }

    Write-Output $root
    Show-PwshTree -Path $root -MaxDepth $Depth
}

function llt {
    [CmdletBinding()]
    param([string]$Path = '.')

    lt -Path $Path -Depth 2
}

function nvg {
    [CmdletBinding()]
    param([Parameter(ValueFromRemainingArguments)][string[]]$Arguments)

    $neovide = Get-Command neovide -CommandType Application -ErrorAction SilentlyContinue
    if (-not $neovide) {
        throw 'nvg requires Neovide to be installed and available on PATH.'
    }

    & $neovide.Source --frame none @Arguments
}

# Preserve PowerShell's built-in rmdir alias. Recursive deletion is explicit.
function rdtree {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [string[]]$Path
    )

    process {
        foreach ($target in $Path) {
            if (-not (Test-Path -LiteralPath $target -PathType Container)) {
                throw "Directory does not exist: $target"
            }

            if ($PSCmdlet.ShouldProcess($target, 'Delete directory recursively and forcefully')) {
                Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction Stop
            }
        }
    }
}
