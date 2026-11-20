# Project directory default.
if ([string]::IsNullOrWhiteSpace($env:PROJECTS_DIR)) {
    $env:PROJECTS_DIR = if (Test-Path 'D:\projects' -PathType Container) {
        'D:\projects'
    } else {
        Join-Path $HOME 'projects'
    }
}
