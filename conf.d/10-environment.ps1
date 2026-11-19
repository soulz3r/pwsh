# Shared environment defaults.
# Prefer the user's existing D:\projects folder, then fall back to ~/projects.
if ([string]::IsNullOrWhiteSpace($env:PROJECTS_DIR)) {
    $defaultProjects = 'D:\projects'
    if (Test-Path -LiteralPath $defaultProjects -PathType Container) {
        $env:PROJECTS_DIR = $defaultProjects
    } else {
        $env:PROJECTS_DIR = Join-Path $HOME 'projects'
    }
}
