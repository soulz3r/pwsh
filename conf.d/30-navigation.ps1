# zoxide replaces cd only when installed.
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    zoxide init powershell --cmd cd | Out-String | Invoke-Expression
}

function mkcd {
    [CmdletBinding()]
    param([Parameter(Mandatory, Position = 0)][string]$Path)

    $null = New-Item -ItemType Directory -Path $Path -Force -ErrorAction Stop
    Set-Location -LiteralPath $Path
}

function croot {
    [CmdletBinding()]
    param([string]$Path = $env:PROJECTS_DIR)

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "Project root does not exist: $Path"
    }
    Set-Location -LiteralPath $Path
}

function cproj {
    [CmdletBinding()]
    param([string]$Root = $env:PROJECTS_DIR)

    if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
        throw "Project root does not exist: $Root"
    }
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        throw 'cproj requires fzf.'
    }

    $markers = @('.git', 'CMakeLists.txt', 'Makefile', 'Cargo.toml', 'package.json', 'pyproject.toml', 'go.mod', 'build.zig')
    $candidates = Get-ChildItem -LiteralPath $Root -Directory -Recurse -Depth 3 -ErrorAction SilentlyContinue
    $projects = foreach ($directory in $candidates) {
        foreach ($marker in $markers) {
            if (Test-Path -LiteralPath (Join-Path $directory.FullName $marker)) {
                $directory.FullName
                break
            }
        }
    }

    $selected = $projects | Sort-Object -Unique | fzf --prompt='project ❯ ' --height=40% --layout=reverse
    if (-not [string]::IsNullOrWhiteSpace($selected)) {
        Set-Location -LiteralPath $selected.Trim()
    }
}

function ff {
    [CmdletBinding()]
    param([string]$Root = (Get-Location).Path)

    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        throw 'ff requires fzf.'
    }

    $selected = Get-ChildItem -LiteralPath $Root -File -Recurse -Force -ErrorAction SilentlyContinue |
        ForEach-Object FullName |
        fzf --prompt='file ❯ ' --height=60% --layout=reverse

    if (-not [string]::IsNullOrWhiteSpace($selected)) {
        Set-Clipboard -Value $selected.Trim()
    }
}
