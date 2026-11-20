# Navigation shortcuts.
if (Get-Command zoxide -CommandType Application -ErrorAction SilentlyContinue) {
    Invoke-Expression (& zoxide init powershell | Out-String)
}

function croot {
    Set-Location -LiteralPath $env:PROJECTS_DIR
}

function up {
    param([ValidateRange(1, 20)][int]$Count = 1)
    $path = ('../' * $Count)
    Set-Location -Path $path
}

function mkcd {
    param([Parameter(Mandatory, Position = 0)][string]$Path)
    $null = New-Item -ItemType Directory -Path $Path -Force
    Set-Location -LiteralPath $Path
}
