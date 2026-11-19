# pwsh

A modular PowerShell profile built around a fast interactive shell, practical terminal workflows, and an Everforest-inspired prompt.

## Prompt

The prompt is deliberately two lines:

- The first line shows the current path and Git branch, with separate markers for staged and working-tree changes.
- The second line places the compact Vi indicator ( I,  N,  V,  O, or  R) immediately beside the input prompt.
- Commands taking at least one second show their duration on the input line.
- A failed command changes the prompt symbol to the error color.

The Vi indicator stays beside the cursor instead of being pushed to the far-right edge of the terminal. Git status is local-only; the prompt does not calculate remote ahead/behind counts on every render.

## Features

- Repository-local Oh My Posh theme using the current config format.
- PSReadLine Vi editing with the Oh My Posh live mode-change handler.
- Everforest colors, local Git status, and command execution time.
- Optional zoxide, fd, fzf, PSFzf, and lsd integrations.
- Project navigation with croot and cproj.
- Bounded fuzzy file search with ff.
- Filesystem commands ls, ll, la, lt, and llt.
- Directory creation with mkcd and explicit recursive deletion with rdtree.
- Neovide launcher nvg, with the previous nvm shortcut retained when Node Version Manager is not installed.
- Idempotent SilkTerm shell integration.
- Symlink-aware installer and behavioral smoke tests.

## Layout

~~~text
pwsh/
├── .github/workflows/powershell.yml
├── conf.d/
├── docs/design-decisions.md
├── tests/validate.ps1
├── install.ps1
├── Microsoft.PowerShell_profile.ps1
├── zen.toml
└── README.md
~~~

The root profile is the entrypoint and loader. Put features in focused files under conf.d; files load alphabetically. PSReadLine configures Vi editing first. Oh My Posh's vimode segment installs the script-based mode-change handler and redraws the prompt when the mode changes. zoxide initializes after Oh My Posh and uses its change-aware hook on modern PowerShell. The zoxide prompt wrapper is expected: it calls the saved prompt and then updates directory history. If Oh My Posh or the theme is unavailable, PSReadLine falls back to its visible cursor indicator.

## Requirements

PowerShell 7 is recommended. The prompt uses [Oh My Posh](https://ohmyposh.dev/) and a [Nerd Font](https://www.nerdfonts.com/) for the Vim glyph.

Optional integrations: [zoxide](https://github.com/ajeetdsouza/zoxide), [fd](https://github.com/sharkdp/fd), [fzf](https://github.com/junegunn/fzf), [PSFzf](https://github.com/kelleyma49/PSFzf), [lsd](https://github.com/lsd-rs/lsd), and [Neovide](https://neovide.dev/).

Install PSFzf with Install-Module PSFzf -Scope CurrentUser.

## Install

~~~powershell
git clone https://github.com/soulz3r/pwsh.git D:\config\powershell
Set-Location D:\config\powershell
~~~

If your profile already symlinks directly to this repository's Microsoft.PowerShell_profile.ps1, that is already the correct setup. Do not add another loader to the linked file.

For setups without that symlink:

~~~powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
~~~

You can target a separate profile path when testing:

~~~powershell
pwsh -NoProfile -File .\install.ps1 -ProfilePath "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
~~~

The installer preserves existing profile content, creates a timestamped backup before changing a regular profile file, and refuses to write through unrelated symlinks. It does not install Oh My Posh.

## Commands

| Command | Purpose |
|---|---|
| croot | Jump to PROJECTS_DIR |
| cproj | Find a project directory using fzf |
| mkcd path | Create a directory and enter it |
| ff [path] | Fuzzy-find a file and copy its full path |
| ls, ll, la | Directory listings |
| lt, llt | Tree listings |
| rdtree path | Recursively delete a directory; supports WhatIf and Confirm |
| nvg | Launch Neovide |

The project root uses D:\projects when it exists, otherwise ~/projects. Set PROJECTS_DIR before loading the profile to override it.

Search prefers fd and streams results directly into fzf so the selector can open before the full tree has been scanned. The PowerShell fallback for ff is deliberately limited to five directory levels. Search and tree commands skip common generated/vendor directories such as .git, node_modules, build, and target. Project discovery falls back to a bounded PowerShell traversal if fd fails.

Preview deletion with rdtree -WhatIf .\some-folder. PowerShell's built-in rmdir alias is left untouched.

## Checks

Run ./tests/validate.ps1 locally. GitHub Actions runs the same behavior checks and PSScriptAnalyzer on pushes and pull requests targeting main.

See docs/design-decisions.md for ownership and safety rules.
