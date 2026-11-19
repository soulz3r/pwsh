# Optional project navigation and fuzzy search.
if (Get-Command zoxide -ErrorAction SilentlyContinue) { zoxide init powershell --cmd cd | Out-String | Invoke-Expression }

function mkcd {
    [CmdletBinding()] param([Parameter(Mandatory, Position = 0)][string]$Path)
    $null = New-Item -ItemType Directory -Path $Path -Force -ErrorAction Stop
    Set-Location -LiteralPath $Path
}

function croot {
    [CmdletBinding()] param([string]$Path = $env:PROJECTS_DIR)
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path -PathType Container)) { throw "Project root does not exist: $Path" }
    Set-Location -LiteralPath $Path
}

function Test-PwshProjectDirectory {
    param([Parameter(Mandatory)][string]$Path)
    foreach ($marker in @('.git','CMakeLists.txt','CMakePresets.json','Makefile','meson.build','Cargo.toml','package.json','pyproject.toml','go.mod','build.zig')) {
        if (Test-Path -LiteralPath (Join-Path $Path $marker)) { return $true }
    }
    foreach ($pattern in @('*.sln','*.slnx','*.vcxproj')) {
        if (Get-ChildItem -LiteralPath $Path -File -Filter $pattern -ErrorAction SilentlyContinue | Select-Object -First 1) { return $true }
    }
    return $false
}

function Get-PwshProjectDirectories {
    param([Parameter(Mandatory)][string]$Root)
    $excluded = @('.git','node_modules','.venv','venv','bin','obj','build','dist','target')
    $fd = Get-Command fd -ErrorAction SilentlyContinue
    if ($fd) {
        $arguments = @('--type','d','--hidden','--max-depth','3','--color','never')
        foreach ($name in $excluded) { $arguments += @('--exclude',$name) }
        & $fd.Source @arguments '.' $Root 2>$null
        return
    }
    Get-PwshDirectoriesFallback -Root $Root -MaxDepth 3
}

function Get-PwshDirectoriesFallback {
    param([Parameter(Mandatory)][string]$Root,[int]$MaxDepth = 3)
    $excluded = @('.git','node_modules','.venv','venv','bin','obj','build','dist','target')
    $pending = [System.Collections.Generic.Stack[object]]::new()
    $pending.Push([pscustomobject]@{ Path = $Root; Depth = 0 })
    while ($pending.Count -gt 0) {
        $current = $pending.Pop()
        if ($current.Depth -ge $MaxDepth) { continue }
        Get-ChildItem -LiteralPath $current.Path -Directory -Force -ErrorAction SilentlyContinue |
            ForEach-Object {
                if ($_.Name -notin $excluded -and -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
                    $_.FullName
                    $pending.Push([pscustomobject]@{ Path = $_.FullName; Depth = $current.Depth + 1 })
                }
            }
    }
}

function Get-PwshFilesFallback {
    param([Parameter(Mandatory)][string]$Root,[int]$MaxDepth = 5)
    $excluded = @('.git','node_modules','.venv','venv','bin','obj','build','dist','target')
    $pending = [System.Collections.Generic.Stack[object]]::new()
    $pending.Push([pscustomobject]@{ Path = $Root; Depth = 0 })
    while ($pending.Count -gt 0) {
        $current = $pending.Pop()
        Get-ChildItem -LiteralPath $current.Path -Force -ErrorAction SilentlyContinue |
            ForEach-Object {
                if ($_.PSIsContainer) {
                    if ($current.Depth -lt $MaxDepth -and $_.Name -notin $excluded -and -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
                        $pending.Push([pscustomobject]@{ Path = $_.FullName; Depth = $current.Depth + 1 })
                    }
                } else {
                    $_.FullName
                }
            }
    }
}

function cproj {
    [CmdletBinding()] param([string]$Root = $env:PROJECTS_DIR)
    if ([string]::IsNullOrWhiteSpace($Root) -or -not (Test-Path -LiteralPath $Root -PathType Container)) { throw "Project root does not exist: $Root" }
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) { throw 'cproj requires fzf.' }
    $directories = @($Root) + @(Get-PwshProjectDirectories -Root $Root)
    $projects = foreach ($directory in ($directories | Sort-Object -Unique)) {
        if (Test-PwshProjectDirectory -Path $directory) { (Resolve-Path -LiteralPath $directory).Path }
    }
    $selected = $projects | Sort-Object -Unique | fzf --prompt='project ❯ ' --height=40% --layout=reverse
    if (-not [string]::IsNullOrWhiteSpace($selected)) { Set-Location -LiteralPath $selected.Trim() }
}

function ff {
    [CmdletBinding()] param([string]$Root = (Get-Location).Path)
    if (-not (Test-Path -LiteralPath $Root -PathType Container)) { throw "Search root does not exist: $Root" }
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) { throw 'ff requires fzf.' }
    $fd = Get-Command fd -ErrorAction SilentlyContinue
    if ($fd) {
        $files = & $fd.Source --type f --hidden --color never --exclude .git --exclude node_modules --exclude .venv --exclude venv --exclude bin --exclude obj --exclude build --exclude dist --exclude target '.' $Root 2>$null
    } else {
        $files = Get-PwshFilesFallback -Root $Root -MaxDepth 5
    }
    $selected = $files | fzf --prompt='file ❯ ' --height=60% --layout=reverse
    if (-not [string]::IsNullOrWhiteSpace($selected)) { Set-Clipboard -Value $selected.Trim() }
}
