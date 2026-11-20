# pwsh

A minimal PowerShell profile with Oh My Posh, Git context, Vi editing, and a few useful shortcuts.

## Prompt

Two plain lines, no boxes or powerline separators:

```text
D:/projects  main
 I ❯
```

The first line shows the current path and local Git branch. `+` marks staged changes and `*` marks working-tree changes. The second line shows the PSReadLine Vi mode. Oh My Posh handles prompt rendering and mode-change redraw.

## Shortcuts

| Shortcut | Purpose |
|---|---|
| `c` | Change directory |
| `croot` | Go to `PROJECTS_DIR` |
| `mkcd name` | Create a directory and enter it |
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
| `v` | Neovim |

Git shortcuts pass remaining arguments directly to Git.

## Requirements

PowerShell 7, Oh My Posh, a Nerd Font, and PSReadLine. zoxide is optional.

The project directory defaults to `D:\projects` when it exists, otherwise `~/projects`. Set `PROJECTS_DIR` to override it.

## Install

```powershell
Set-Location D:\config\powershell
. .\Microsoft.PowerShell_profile.ps1
```

Run `./tests/validate.ps1` to check the profile.
