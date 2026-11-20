# Optional zoxide integration.
$zoxide = Get-Command zoxide -CommandType Application -ErrorAction SilentlyContinue
if ($zoxide) {
    $hook = if ($PSVersionTable.PSVersion.Major -ge 6) { 'pwd' } else { 'prompt' }
    $init = @(& $zoxide.Source init powershell --cmd cd --hook $hook)
    if ($LASTEXITCODE -eq 0 -and $init) {
        # 20-prompt restores the underlying prompt on reload.
        $global:__zoxide_hooked = 0
        Invoke-Expression ($init -join [Environment]::NewLine)
    } else {
        Write-Warning 'zoxide initialization failed.'
    }
}

function croot {
    if (-not (Test-Path -LiteralPath $env:PROJECTS_DIR -PathType Container)) {
        throw "Project directory does not exist: $env:PROJECTS_DIR"
    }
    Set-Location -LiteralPath $env:PROJECTS_DIR
}

function mkcd {
    param([Parameter(Mandatory, Position = 0)][string]$Path)
    $null = New-Item -ItemType Directory -Path $Path -Force
    Set-Location -LiteralPath $Path
}
