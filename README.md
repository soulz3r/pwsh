# pwsh

A modular PowerShell profile built around a fast interactive shell, practical terminal workflows, and an Everforest-inspired prompt.

## Features

- Repository-local Oh My Posh theme. No dependency on fish.git.
- PSReadLine Vi editing with a live Oh My Posh mode indicator.
- Compact Vim labels: ` I`, ` N`, ` V`, ` O`, and ` R`.
- Everforest colors, Git status, and command execution time.
- Optional zoxide, fzf, PSFzf, and lsd integrations.
- Project navigation with `croot` and `cproj`.
- File search with `ff`, directory creation with `mkcd`, and safe recursive `rmdir`.
- SilkTerm shell integration isolated from the rest of the profile.
- PowerShell parser checks and PSScriptAnalyzer in GitHub Actions.

Optional tools are checked before use. Missing optional executables should not prevent the profile from loading.

## Layout

~~~text
pwsh/
├── .github/workflows/powershell.yml
├── conf.d/
│   ├── 10-environment.ps1
│   ├── 15-readline.ps1
│   ├── 20-prompt.ps1
│   ├── 30-navigation.ps1
│   ├── 40-filesystem.ps1
│   ├── 60-fzf.ps1
│   └── 90-silkterm.ps1
├── tests/validate.ps1
├── Microsoft.PowerShell_profile.ps1
├── zen.toml
├── .gitignore
└── LICENSE
~~~

The root profile is a loader. Put new features in a focused file under `conf.d/`; files are loaded alphabetically. PSReadLine Vi mode loads before Oh My Posh so its live mode hook is initialized correctly.

## Requirements

PowerShell 7 is recommended.

The prompt uses:
- [Oh My Posh](https://ohmyposh.dev/)
- A [Nerd Font](https://www.nerdfonts.com/) for the Vim glyph.

Optional integrations:
- [zoxide](https://github.com/ajeetdsouza/zoxide)
- [fzf](https://github.com/junegunn/fzf)
- [PSFzf](https://github.com/kelleyma49/PSFzf)
- [lsd](https://github.com/lsd-rs/lsd)
- [Neovide](https://neovide.dev/)

Install PSFzf:

~~~powershell
Install-Module PSFzf -Scope CurrentUser
~~~

## Install

Back up your current profile:

~~~powershell
Copy-Item $PROFILE "$PROFILE.backup" -Force
~~~

Clone the repository:

~~~powershell
git clone https://github.com/soulz3r/pwsh.git "$HOME/.config/powershell"
~~~

Make the PowerShell profile load this repository. Run once:

~~~powershell
$profileRoot = Join-Path $HOME '.config/powershell'
New-Item -ItemType Directory -Path (Split-Path $PROFILE) -Force | Out-Null
Set-Content -LiteralPath $PROFILE -Value ". '$profileRoot/Microsoft.PowerShell_profile.ps1'"
~~~

Restart PowerShell, or reload with:

~~~powershell
. $PROFILE
~~~

If you keep the clone elsewhere, change `$profileRoot` to that path.

## Commands

| Command | Purpose |
| --- | --- |
| `croot` | Jump to `$env:PROJECTS_DIR` |
| `cproj` | Find a project directory using fzf |
| `mkcd path` | Create a directory and enter it |
| `ff [path]` | Fuzzy-find a file and copy its full path |
| `ls`, `ll`, `la` | Directory listings |
| `lt`, `llt` | Tree listings |
| `rmdir path` | Recursively remove a directory; supports `-WhatIf` |

The project root uses `D:\projects` when it exists, otherwise it defaults to `~/projects`. Set `$env:PROJECTS_DIR` before loading the profile to override it.

Preview a deletion before doing it:

~~~powershell
rmdir -WhatIf .\some-folder
~~~

## Checks

Run the local checks:

~~~powershell
./tests/validate.ps1
~~~

GitHub Actions runs the same parser and profile-loading checks, followed by PSScriptAnalyzer, on pushes and pull requests to `main`.
