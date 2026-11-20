# pwsh

A small PowerShell profile with Vi editing, a plain prompt, and short commands.

## Prompt

One line. Current directory and an input arrow.

```text
D:\projects ❯
```

No Oh My Posh, prompt plugins, Git status checks, or decorative segments.

## Shortcuts

| Shortcut | Command |
|---|---|
| `c` | `Set-Location` |
| `up [n]` | Go up *n* directories |
| `croot` | Go to `PROJECTS_DIR` |
| `mkcd name` | Create a directory and enter it |
| `ll` | List in table form |
| `la` | List including hidden items |
| `touch file` | Create a file or update its timestamp |
| `which name` | Find a command |
| `g` | Run Git |
| `gs` | Git status |
| `ga` | Git add |
| `gco` | Git switch |
| `gcb` | Create and switch to a branch |
| `gcm` | Git commit |
| `gpl` | Git pull with fast-forward only |
| `gps` | Git push |
| `glog` | Compact graph log |
| `v` | Neovim |
| `nvg` | Neovide |

Git shortcuts pass their remaining arguments to Git. PowerShell does not have Fish-style abbreviations built in, so these are small functions and aliases.

## Optional tools

- PowerShell 7
- PSReadLine (included with current PowerShell)
- zoxide (optional; enables `z`)

The project directory defaults to `D:\projects` when it exists, otherwise `~/projects`. Set `PROJECTS_DIR` to override it.

## Install

```powershell
git clone https://github.com/soulz3r/pwsh.git D:\config\powershell
Set-Location D:\config\powershell
. .\Microsoft.PowerShell_profile.ps1
```

To register the profile for future sessions:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

## Checks

Run `./tests/validate.ps1`. GitHub Actions runs the same checks and PSScriptAnalyzer on pushes to `main`.
