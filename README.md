# pwsh

A modular PowerShell profile built around a fast interactive shell, practical terminal workflows, and an Everforest-inspired prompt.

## Features
- Repository-local Oh My Posh theme.
- PSReadLine Vi editing with Oh My Posh live mode indicator integration.
- Compact Vim labels: ` I`, ` N`, ` V`, ` O`, and ` R`.
- Everforest colors, Git status, and command execution time.
- Optional zoxide, fd, fzf, PSFzf, and lsd integrations.
- Project navigation with `croot` and `cproj`.
- File search with `ff`, directory creation with `mkcd`, and explicit recursive deletion with `rdtree`.
- Idempotent SilkTerm shell integration.
- Symlink-aware installer and behavioral smoke tests.

## Layout
```text
pwsh/
├── .github/workflows/powershell.yml
├── conf.d/
├── docs/design-decisions.md
├── tests/validate.ps1
├── install.ps1
├── Microsoft.PowerShell_profile.ps1
├── zen.toml
└── README.md
```

The root profile is the entrypoint and loader. Put features in focused files under `conf.d/`; files load alphabetically. PSReadLine configures Vi editing first. Oh My Posh initializes its own live Vi-mode callback and prompt indicator.

## Requirements
PowerShell 7 is recommended. The prompt uses [Oh My Posh](https://ohmyposh.dev/) and a [Nerd Font](https://www.nerdfonts.com/) for the Vim glyph.

Optional integrations: [zoxide](https://github.com/ajeetdsouza/zoxide), [fd](https://github.com/sharkdp/fd), [fzf](https://github.com/junegunn/fzf), [PSFzf](https://github.com/kelleyma49/PSFzf), [lsd](https://github.com/lsd-rs/lsd), and [Neovide](https://neovide.dev/).

Install PSFzf with `Install-Module PSFzf -Scope CurrentUser`.

## Install
```powershell
git clone https://github.com/soulz3r/pwsh.git D:\config\powershell
Set-Location D:\config\powershell
```

If your profile already symlinks directly to this repository's `Microsoft.PowerShell_profile.ps1`, that is already the correct setup. Do not add another loader to the linked file.

For setups without that symlink:
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

You can target a separate profile path when testing:
```powershell
pwsh -NoProfile -File .\install.ps1 -ProfilePath "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
```

The installer preserves existing profile content, creates a timestamped backup before changing a regular profile file, and refuses to write through unrelated symlinks. It does not install Oh My Posh.

## Commands
| Command | Purpose |
|---|---|
| `croot` | Jump to `$env:PROJECTS_DIR` |
| `cproj` | Find a project directory using fzf |
| `mkcd path` | Create a directory and enter it |
| `ff [path]` | Fuzzy-find a file and copy its full path |
| `ls`, `ll`, `la` | Directory listings |
| `lt`, `llt` | Tree listings |
| `rdtree path` | Recursively delete a directory; supports `-WhatIf` and `-Confirm` |
| `nvg` | Launch Neovide |

The project root uses `D:\projects` when it exists, otherwise `~/projects`. Set `$env:PROJECTS_DIR` before loading the profile to override it.

Search prefers `fd` and excludes common generated/vendor directories. PowerShell provides a fallback when `fd` is unavailable.

Preview deletion with `rdtree -WhatIf .\some-folder`. PowerShell's built-in `rmdir` alias is left untouched.

## Checks
Run `./tests/validate.ps1` locally. GitHub Actions runs validation and PSScriptAnalyzer on pushes to `main` and `hardening`, and pull requests targeting `main`.

See [design decisions](docs/design-decisions.md) for ownership and safety rules.
