$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$script:failed = $false

function Assert-Condition {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        $script:failed = $true
        Write-Host "[FAIL] $Message" -ForegroundColor Red
    } else {
        Write-Host "[PASS] $Message" -ForegroundColor Green
    }
}

$files = Get-ChildItem -LiteralPath $root -Filter '*.ps1' -File -Recurse |
    Where-Object { $_.FullName -notmatch '[\\/](\.git|\.github)[\\/]' }

foreach ($file in $files) {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile(
        $file.FullName,
        [ref]$tokens,
        [ref]$errors
    ) | Out-Null

    Assert-Condition ($errors.Count -eq 0) "PowerShell syntax: $($file.FullName)"
    foreach ($parseError in $errors) {
        Write-Host "       $($parseError.Message)" -ForegroundColor Red
    }
}

$required = @(
    'Microsoft.PowerShell_profile.ps1',
    'install.ps1',
    'zen.toml',
    'conf.d/10-environment.ps1',
    'conf.d/15-readline.ps1',
    'conf.d/20-prompt.ps1',
    'conf.d/30-navigation.ps1',
    'conf.d/40-filesystem.ps1',
    'conf.d/60-fzf.ps1',
    'conf.d/90-silkterm.ps1',
    'docs/design-decisions.md'
)

foreach ($relativePath in $required) {
    $fullPath = Join-Path $root $relativePath
    Assert-Condition (Test-Path -LiteralPath $fullPath -PathType Leaf) "Required file: $relativePath"
}

$theme = Get-Content -LiteralPath (Join-Path $root 'zen.toml') -Raw
$vimodeIndex = $theme.IndexOf("type = 'vimode'", [StringComparison]::Ordinal)
$promptIndex = $theme.IndexOf("type = 'text'", [StringComparison]::Ordinal)
Assert-Condition ($theme -match '(?m)^version\s*=\s*4\s*$') 'Oh My Posh theme uses current config version'
Assert-Condition ($vimodeIndex -ge 0 -and $promptIndex -gt $vimodeIndex) 'Vi mode renders before the prompt symbol'
Assert-Condition ($theme -notmatch "(?m)^\s*type\s*=\s*'rprompt'\s*$") 'Prompt does not use a far-right mode indicator'
Assert-Condition ($theme -notmatch '\\.Behind|\\.Ahead') 'Git prompt avoids ahead/behind status probes'
Assert-Condition ($theme -notmatch '(?m)^\s*fetch_status\s*=') 'Git prompt does not use an obsolete fetch_status option'
Assert-Condition ($theme.Contains("style = 'plain'")) 'Prompt uses plain text segments'
Assert-Condition ($theme -notmatch 'leading_diamond|trailing_diamond|powerline_symbol||') 'Prompt has no boxes or powerline separators'
Assert-Condition ($theme.Contains("template = '{{ .Path }}'")) 'Path renders without decorative icons'
Assert-Condition ($theme.Contains("template = '  {{ .HEAD }}")) 'Git branch stays compact'
Assert-Condition ($theme.Contains("template = ' {{if eq .Mode")) 'Vi indicator stays beside the input line'
Assert-Condition ($theme.Contains("template = ' ❯ '")) 'Input arrow has minimal spacing'
$navigationSource = Get-Content -LiteralPath (Join-Path $root 'conf.d/30-navigation.ps1') -Raw
Assert-Condition ($navigationSource -match '--hook \$hookMode') 'zoxide uses an explicit change-aware hook on modern PowerShell'
Assert-Condition ($navigationSource -match '\$global:__zoxide_hooked = 0') 'zoxide hook is reinstalled after profile reload'
Assert-Condition ($navigationSource -notmatch '\$files = @\(& \$fd\.Source') 'ff does not buffer the complete fd result before fzf'

if (-not $script:failed) {
    . (Join-Path $root 'Microsoft.PowerShell_profile.ps1')
    . (Join-Path $root 'Microsoft.PowerShell_profile.ps1')

    # zoxide must wrap the freshly initialized prompt after repeated sourcing.
    $zoxideCommand = Get-Command zoxide -CommandType Application -ErrorAction SilentlyContinue
    if ($zoxideCommand) {
        Assert-Condition ($global:__zoxide_hooked -eq 1) 'Zoxide hook remains initialized after repeated profile loads'
        Assert-Condition ($global:__zoxide_prompt_old -is [scriptblock]) 'Zoxide retains the underlying prompt after reload'
        Assert-Condition (
            $global:__zoxide_prompt_old.ToString() -notmatch '__zoxide_hook'
        ) 'Zoxide does not save its own wrapper as the underlying prompt'
    }

    foreach ($name in @('croot', 'cproj', 'mkcd', 'ff', 'rdtree', 'nvg', 'ls', 'll', 'la', 'lt', 'llt')) {
        Assert-Condition ([bool](Get-Command $name -CommandType Function -ErrorAction SilentlyContinue)) "Profile function: $name"
    }

    $resolvedLs = Get-Command ls -ErrorAction Stop
    Assert-Condition ($resolvedLs.CommandType -eq 'Function') 'ls resolves to the profile function'
    $rmdirCommand = Get-Command rmdir -ErrorAction Stop
    Assert-Condition (
        $rmdirCommand.CommandType -eq 'Alias' -and $rmdirCommand.Definition -eq 'rdtree'
    ) 'rmdir preserves the legacy recursive-delete shortcut'
    $nvmCommand = Get-Command nvm -ErrorAction SilentlyContinue
    if ($nvmCommand -and $nvmCommand.CommandType -eq 'Alias') {
        Assert-Condition ($nvmCommand.Definition -eq 'nvg') 'Legacy nvm shortcut points to Neovide when nvm is otherwise unused'
    }

    # croot must fail cleanly when its configured root is empty.
    $previousProjectsDir = $env:PROJECTS_DIR
    try {
        $env:PROJECTS_DIR = ''
        $crootFailedCleanly = $false
        try {
            croot
        } catch {
            $crootFailedCleanly = $_.Exception.Message -like 'Project root does not exist:*'
        }
        Assert-Condition $crootFailedCleanly 'croot handles an empty project root'
    } finally {
        $env:PROJECTS_DIR = $previousProjectsDir
    }

    # mkcd must treat wildcard characters as literal directory-name characters.
    $mkcdRoot = Join-Path ([IO.Path]::GetTempPath()) ("pwsh-mkcd-test-" + [guid]::NewGuid())
    $specialDirectory = Join-Path $mkcdRoot 'folder[one]'
    $originalLocation = Get-Location
    try {
        mkcd $specialDirectory
        Assert-Condition (Test-Path -LiteralPath $specialDirectory -PathType Container) 'mkcd creates a literal path containing brackets'
    } finally {
        Set-Location -LiteralPath $originalLocation
        Remove-Item -LiteralPath $mkcdRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    # The tree fallback should be readable, bounded, and avoid generated/vendor trees.
    $treeRoot = Join-Path ([IO.Path]::GetTempPath()) ("pwsh-tree-test-" + [guid]::NewGuid())
    $null = New-Item -ItemType Directory -Path (Join-Path $treeRoot 'src') -Force
    $null = New-Item -ItemType Directory -Path (Join-Path $treeRoot 'node_modules') -Force
    Set-Content -LiteralPath (Join-Path $treeRoot 'src/main.c') -Value 'int main(void) { return 0; }'
    Set-Content -LiteralPath (Join-Path $treeRoot 'node_modules/ignored.js') -Value 'ignored'
    try {
        $treeOutput = @(Show-PwshTree -Path $treeRoot -MaxDepth 3)
        $treeText = $treeOutput -join [Environment]::NewLine
        Assert-Condition ($treeText -match 'src[\\/]') 'Tree fallback shows source directories'
        Assert-Condition ($treeText -match 'main\.c') 'Tree fallback shows files'
        Assert-Condition ($treeText -notmatch 'node_modules|ignored\.js') 'Tree fallback skips generated directories'
        Assert-Condition ($treeText -match '└──|├──') 'Tree fallback uses readable branch connectors'
    } finally {
        Remove-Item -LiteralPath $treeRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Project discovery recognizes markers and ignores generated directories.
    $projectRoot = Join-Path ([IO.Path]::GetTempPath()) ("pwsh-project-test-" + [guid]::NewGuid())
    $sourceProject = Join-Path $projectRoot 'source-project'
    $ignoredProject = Join-Path $projectRoot 'node_modules'
    $null = New-Item -ItemType Directory -Path $sourceProject -Force
    $null = New-Item -ItemType Directory -Path $ignoredProject -Force
    Set-Content -LiteralPath (Join-Path $sourceProject 'CMakeLists.txt') -Value 'project(test)'
    Set-Content -LiteralPath (Join-Path $ignoredProject 'package.json') -Value '{}'
    try {
        $discoveredDirectories = @(Get-PwshDirectoriesFallback -Root $projectRoot -MaxDepth 3)
        Assert-Condition (Test-PwshProjectDirectory -Path $sourceProject) 'Project detection recognizes CMake projects'
        Assert-Condition ($discoveredDirectories -contains $sourceProject) 'Project fallback discovers nested directories'
        Assert-Condition (-not ($discoveredDirectories -contains $ignoredProject)) 'Project fallback excludes generated directories'
    } finally {
        Remove-Item -LiteralPath $projectRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Test safe deletion in a disposable directory only.
    $deleteRoot = Join-Path ([IO.Path]::GetTempPath()) ("pwsh-delete-test-" + [guid]::NewGuid())
    $deleteTarget = Join-Path $deleteRoot 'delete-me'
    $null = New-Item -ItemType Directory -Path $deleteTarget -Force
    try {
        rdtree -WhatIf $deleteTarget
        Assert-Condition (Test-Path -LiteralPath $deleteTarget -PathType Container) 'rdtree -WhatIf preserves the target'

        rmdir -WhatIf $deleteTarget
        Assert-Condition (Test-Path -LiteralPath $deleteTarget -PathType Container) 'rmdir alias also honors WhatIf'

        rdtree -Confirm:$false $deleteTarget
        Assert-Condition (-not (Test-Path -LiteralPath $deleteTarget)) 'rdtree deletes only the requested target'
    } finally {
        Remove-Item -LiteralPath $deleteRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Verify the PowerShell ff fallback without fd or fzf.
    $searchRoot = Join-Path ([IO.Path]::GetTempPath()) ("pwsh-search-test-" + [guid]::NewGuid())
    $childRoot = Join-Path $searchRoot 'child'
    $deepRoot = Join-Path $childRoot 'deep'
    $ignoredRoot = Join-Path $searchRoot 'node_modules'
    $null = New-Item -ItemType Directory -Path $deepRoot -Force
    $null = New-Item -ItemType Directory -Path $ignoredRoot -Force
    Set-Content -LiteralPath (Join-Path $searchRoot 'root.txt') -Value 'root'
    Set-Content -LiteralPath (Join-Path $childRoot 'child.txt') -Value 'child'
    Set-Content -LiteralPath (Join-Path $deepRoot 'deep.txt') -Value 'deep'
    Set-Content -LiteralPath (Join-Path $ignoredRoot 'ignored.txt') -Value 'ignored'
    try {
        $boundedFiles = @(Get-PwshFilesFallback -Root $searchRoot -MaxDepth 1)
        $hasRoot = @($boundedFiles | Where-Object { $_ -like '*root.txt' }).Count -eq 1
        $hasChild = @($boundedFiles | Where-Object { $_ -like '*child.txt' }).Count -eq 1
        $hasDeep = @($boundedFiles | Where-Object { $_ -like '*deep.txt' }).Count -gt 0
        $hasIgnored = @($boundedFiles | Where-Object { $_ -like '*ignored.txt' }).Count -gt 0
        Assert-Condition ($hasRoot -and $hasChild -and -not $hasDeep) 'File-search fallback respects its depth limit'
        Assert-Condition (-not $hasIgnored) 'File-search fallback skips generated directories'
    } finally {
        Remove-Item -LiteralPath $searchRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Exercise installer writes against a disposable profile, never the real one.
    $installRoot = Join-Path ([IO.Path]::GetTempPath()) ("pwsh-installer-test-" + [guid]::NewGuid())
    $installProfile = Join-Path $installRoot 'profile.ps1'
    $null = New-Item -ItemType Directory -Path $installRoot -Force
    Set-Content -LiteralPath $installProfile -Value '# existing user content'
    try {
        & (Join-Path $root 'install.ps1') -ProfilePath $installProfile
        $firstInstall = Get-Content -LiteralPath $installProfile -Raw
        Assert-Condition (
            $firstInstall.Contains('# existing user content') -and
            $firstInstall.Contains('# >>> soulz3r/pwsh managed profile >>>')
        ) 'Installer preserves existing content and adds its managed block'

        & (Join-Path $root 'install.ps1') -ProfilePath $installProfile
        $secondInstall = Get-Content -LiteralPath $installProfile -Raw
        $backups = @(Get-ChildItem -LiteralPath $installRoot -Filter 'profile.ps1.backup-*' -File)
        Assert-Condition (
            $firstInstall -ceq $secondInstall -and $backups.Count -eq 1
        ) 'Installer is idempotent and backs up only the first change'
    } finally {
        Remove-Item -LiteralPath $installRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    $linkRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("pwsh-profile-link-" + [guid]::NewGuid())
    $linkPath = Join-Path $linkRoot 'Microsoft.PowerShell_profile.ps1'
    try {
        $null = New-Item -ItemType Directory -Path $linkRoot
        $null = New-Item -ItemType SymbolicLink -Path $linkPath -Target (Join-Path $root 'Microsoft.PowerShell_profile.ps1')
        . $linkPath
        Assert-Condition ([bool](Get-Command croot -CommandType Function -ErrorAction SilentlyContinue)) 'Profile loads through a symbolic link'
    } catch {
        Write-Warning "Symlink test unavailable in this environment: $($_.Exception.Message)"
    } finally {
        if (Test-Path -LiteralPath $linkRoot) {
            Remove-Item -LiteralPath $linkRoot -Recurse -Force
        }
    }

    $pwsh = Join-Path $PSHOME 'pwsh.exe'
    if (Test-Path -LiteralPath $pwsh) {
        $profilePath = (Join-Path $root 'Microsoft.PowerShell_profile.ps1').Replace("'", "''")
        $childCommand = ". '$profilePath'; if (-not (Get-Command croot -CommandType Function -ErrorAction SilentlyContinue)) { exit 7 }; 'isolated profile OK'"
        $childOutput = & $pwsh -NoLogo -NoProfile -Command $childCommand 2>&1
        Assert-Condition ($LASTEXITCODE -eq 0) "Isolated profile process: $($childOutput -join ' ')"
    }
}

if ($script:failed) {
    throw 'PowerShell repository validation failed.'
}

Write-Host 'All PowerShell checks passed.' -ForegroundColor Green
