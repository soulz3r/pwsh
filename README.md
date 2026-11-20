# pwsh

A minimal PowerShell profile with Oh My Posh, Git context, and a few useful shortcuts.

## Prompt

Two plain lines, no boxes or powerline separators:

```text
D:/projects  main
❯
```

The first line shows the current path and local Git branch. `+` marks staged changes and `*` marks working-tree changes. The second line is a plain input prompt. PowerShell keeps its default editing mode; there is no Vi-mode prompt integration.

## Shortcuts

| Shortcut | Purpose |
|---|---|
| `c` | Change directory |
| `croot` | Go to `PROJECTS_DIR` |
| `mkcd name` | Create a directory and enter it |
| `ls` | Use lsd when installed |
| `ll` | lsd long listing |
| `la` | lsd listing including hidden files |
| `lt` | lsd tree |
| `g` | Run Git |
| `gs` | Git status |
| `ga` | Git add |
| `gco` | Git switch |
| `gcb` | Create and switch to a branch |
| `gcm` | Git commit |
| `gpl` | Git pull, fast-forward only |
| `gps` | Git push |
| `glog` | Compact graph log |
| `which` | Find a command |
| `v`, `vi` | Vim |

Git shortcuts pass remaining arguments directly to Git. `fzf`, `fd`, and other installed executables remain directly available on PATH; the profile does not wrap them.

## Requirements

PowerShell 7, Oh My Posh, a Nerd Font, PSReadLine, Git, and Vim. zoxide and lsd are optional.

The project directory defaults to `D:\\projects` when it exists, otherwise `~/projects`. Set `PROJECTS_DIR` to override it.

## Install

```powershell
Set-Location D:\\config\\powershell
. .\\Microsoft.PowerShell_profile.ps1
```

Run `./tests/validate.ps1` to check the profile.
