# Optional project navigation and fuzzy search.
$zoxide = Get-Command zoxide -CommandType Application -ErrorAction SilentlyContinue |
    Select-Object -First 1

if ($zoxide) {
    # The prompt hook is the compatibility path for Windows PowerShell 5.1.
    # PowerShell 6+ supports zoxide's change-aware PWD hook.
    $hookMode = if ($PSVersionTable.PSVersion.Major -ge 6) { 'pwd' } else { 'prompt' }
    $zoxideInit = @(& $zoxide.Source init powershell --cmd cd --hook $hookMode)
    $zoxideExitCode = $LASTEXITCODE

    if ($zoxideExitCode -ne 0 -or -not $zoxideInit) {
        Write-Warning "zoxide initialization failed (exit code: $zoxideExitCode)."
    } else {
        # zoxide guards its prompt wrapper against duplicate initialization.
        # Reset the guard because 20-prompt has just restored/recreated prompt.
        $global:__zoxide_hooked = 0

        try {
            Invoke-Expression ($zoxideInit -join [Environment]::NewLine)
        } catch {
            Write-Warning "zoxide PowerShell integration failed: $($_.Exception.Message)"
        }
    }
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

        $directories = @(& $fd.Source @arguments '.' $rootPath 2>$null)
        $fdExitCode = $LASTEXITCODE

        if ($fdExitCode -le 1) {
            $directories
            return
        }

        Write-Verbose "fd failed while discovering projects under '$rootPath'; using the PowerShell fallback."
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

        # Keep fd and fzf in one pipeline. fzf can render as soon as the first
        # candidates arrive instead of waiting for PowerShell to buffer all files.
        $selected = & $fd.Source @arguments '.' $rootPath |
            & $fzf.Source --prompt='file ❯ ' --height=60% --layout=reverse
    } else {
        $selected = Get-PwshFilesFallback -Root $rootPath -MaxDepth 5 |
            & $fzf.Source --prompt='file ❯ ' --height=60% --layout=reverse
    }

    # Empty output covers Escape/Ctrl+C and a selector with no chosen item.
    if (-not [string]::IsNullOrWhiteSpace($selected)) {
        Set-Clipboard -Value $selected.Trim()
    }
}
