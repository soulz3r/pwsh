# Optional project navigation and fuzzy search.
if (Get-Command zoxide -CommandType Application -ErrorAction SilentlyContinue) {
    zoxide init powershell --cmd cd | Out-String | Invoke-Expression
}

function mkcd {
    [CmdletBinding()]
    param([Parameter(Mandatory, Position = 0)][string]$Path)

    # Resolve as a PowerShell provider path before using .NET so wildcard
    # characters in a literal directory name are not treated as patterns.
    $target = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    $null = [System.IO.Directory]::CreateDirectory($target)
    Set-Location -LiteralPath $target
}

function croot {
    [CmdletBinding()]
    param([string]$Path = $env:PROJECTS_DIR)

    if ([string]::IsNullOrWhiteSpace($Path) -or
        -not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "Project root does not exist: $Path"
    }

    Set-Location -LiteralPath $Path
}

function Test-PwshProjectDirectory {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    foreach ($marker in @(
        '.git', 'CMakeLists.txt', 'CMakePresets.json', 'Makefile',
        'meson.build', 'Cargo.toml', 'package.json', 'pyproject.toml',
        'go.mod', 'build.zig'
    )) {
        if (Test-Path -LiteralPath (Join-Path $Path $marker)) {
            return $true
        }
    }

    foreach ($pattern in @('*.sln', '*.slnx', '*.vcxproj')) {
        $match = Get-ChildItem -LiteralPath $Path -File -Filter $pattern -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($match) {
            return $true
        }
    }

    return $false
}

function Get-PwshProjectDirectories {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Root)

    $rootPath = (Resolve-Path -LiteralPath $Root -ErrorAction Stop).ProviderPath
    $excluded = @(
        '.git', 'node_modules', '.venv', 'venv', 'bin', 'obj',
        'build', 'dist', 'target', '.cache'
    )
    $fd = Get-Command fd -CommandType Application -ErrorAction SilentlyContinue

    if ($fd) {
        $arguments = @('--type', 'd', '--hidden', '--max-depth', '3', '--color', 'never')
        foreach ($name in $excluded) {
            $arguments += @('--exclude', $name)
        }

        & $fd.Source @arguments '.' $rootPath 2>$null
        return
    }

    Get-PwshDirectoriesFallback -Root $rootPath -MaxDepth 3
}

function Get-PwshDirectoriesFallback {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Root,
        [ValidateRange(0, 20)][int]$MaxDepth = 3
    )

    $excluded = @(
        '.git', 'node_modules', '.venv', 'venv', 'bin', 'obj',
        'build', 'dist', 'target', '.cache'
    )
    $pending = [System.Collections.Generic.Stack[object]]::new()
    $pending.Push([pscustomobject]@{ Path = $Root; Depth = 0 })

    while ($pending.Count -gt 0) {
        $current = $pending.Pop()
        if ($current.Depth -ge $MaxDepth) {
            continue
        }

        $children = Get-ChildItem -LiteralPath $current.Path -Directory -Force -ErrorAction SilentlyContinue
        foreach ($child in $children) {
            if ($child.Name -in $excluded -or
                ($child.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
                continue
            }

            $child.FullName
            $pending.Push([pscustomobject]@{
                Path = $child.FullName
                Depth = $current.Depth + 1
            })
        }
    }
}

function Get-PwshFilesFallback {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Root,
        [ValidateRange(0, 20)][int]$MaxDepth = 5
    )

    $excluded = @(
        '.git', 'node_modules', '.venv', 'venv', 'bin', 'obj',
        'build', 'dist', 'target', '.cache'
    )
    $pending = [System.Collections.Generic.Stack[object]]::new()
    $pending.Push([pscustomobject]@{ Path = $Root; Depth = 0 })

    while ($pending.Count -gt 0) {
        $current = $pending.Pop()
        $entries = Get-ChildItem -LiteralPath $current.Path -Force -ErrorAction SilentlyContinue

        foreach ($entry in $entries) {
            if ($entry.PSIsContainer) {
                if ($current.Depth -lt $MaxDepth -and
                    $entry.Name -notin $excluded -and
                    -not ($entry.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
                    $pending.Push([pscustomobject]@{
                        Path = $entry.FullName
                        Depth = $current.Depth + 1
                    })
                }
            } else {
                $entry.FullName
            }
        }
    }
}

function cproj {
    [CmdletBinding()]
    param([string]$Root = $env:PROJECTS_DIR)

    if ([string]::IsNullOrWhiteSpace($Root) -or
        -not (Test-Path -LiteralPath $Root -PathType Container)) {
        throw "Project root does not exist: $Root"
    }

    $fzf = Get-Command fzf -CommandType Application -ErrorAction SilentlyContinue
    if (-not $fzf) {
        throw 'cproj requires fzf.'
    }

    $rootPath = (Resolve-Path -LiteralPath $Root -ErrorAction Stop).ProviderPath
    $directories = @($rootPath) + @(Get-PwshProjectDirectories -Root $rootPath)
    $projects = @(
        foreach ($directory in ($directories | Sort-Object -Unique)) {
            if (Test-PwshProjectDirectory -Path $directory) {
                (Resolve-Path -LiteralPath $directory -ErrorAction Stop).ProviderPath
            }
        }
    ) | Sort-Object -Unique

    if (-not $projects) {
        Write-Host "No projects found under '$rootPath'." -ForegroundColor DarkGray
        return
    }

    $selected = $projects | & $fzf.Source --prompt='project ❯ ' --height=40% --layout=reverse
    if (-not [string]::IsNullOrWhiteSpace($selected)) {
        Set-Location -LiteralPath $selected.Trim()
    }
}

function ff {
    [CmdletBinding()]
    param([string]$Root = (Get-Location).Path)

    if ([string]::IsNullOrWhiteSpace($Root) -or
        -not (Test-Path -LiteralPath $Root -PathType Container)) {
        throw "Search root does not exist: $Root"
    }

    $fzf = Get-Command fzf -CommandType Application -ErrorAction SilentlyContinue
    if (-not $fzf) {
        throw 'ff requires fzf.'
    }

    $rootPath = (Resolve-Path -LiteralPath $Root -ErrorAction Stop).ProviderPath
    $fd = Get-Command fd -CommandType Application -ErrorAction SilentlyContinue

    if ($fd) {
        $arguments = @('--type', 'f', '--hidden', '--color', 'never')
        foreach ($name in @(
            '.git', 'node_modules', '.venv', 'venv', 'bin',
            'obj', 'build', 'dist', 'target', '.cache'
        )) {
            $arguments += @('--exclude', $name)
        }

        $files = @(& $fd.Source @arguments '.' $rootPath 2>$null)
        if ($LASTEXITCODE -gt 1) {
            throw "fd failed while searching '$rootPath' (exit code: $LASTEXITCODE)."
        }
    } else {
        $files = @(Get-PwshFilesFallback -Root $rootPath -MaxDepth 5)
    }

    if (-not $files) {
        Write-Host "No files found under '$rootPath'." -ForegroundColor DarkGray
        return
    }

    $selected = $files | & $fzf.Source --prompt='file ❯ ' --height=60% --layout=reverse
    if (-not [string]::IsNullOrWhiteSpace($selected)) {
        Set-Clipboard -Value $selected.Trim()
    }
}
