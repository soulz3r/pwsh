# Design decisions

This is a small interactive shell configuration, not a general-purpose PowerShell framework. Keep moving parts low and integration boundaries explicit.

## Ownership
- PSReadLine owns line editing, Vi keymaps, history, predictions, and fallback cursor mode.
- Oh My Posh owns prompt rendering and, when available, its live Vi-mode prompt indicator and callback.
- The theme owns visual presentation only.
- Optional executables and modules must never be required for profile startup.

## Startup
- The root profile resolves its symlink before locating conf.d.
- Components load in lexical order; failures identify the component.
- Components that register global callbacks must be safe to dot-source repeatedly.

## Navigation and search
- Prefer fd for filesystem traversal and retain a PowerShell fallback.
- fzf owns selection; candidate discovery belongs to the producing command.
- Exclude generated/vendor directories by default and do not follow directory symlinks.
- Project discovery recognizes common build-system and version-control markers.

## Filesystem safety
- Do not redefine PowerShell's built-in rmdir alias.
- Forced recursive deletion uses the explicit rdtree command with -WhatIf and -Confirm.
- Listing commands retain useful native fallbacks when lsd is absent.

## Environment and optional tools
- Preserve user-provided environment options; append FZF defaults rather than replacing them.
- Assign environment defaults only when the user has not already set them.
- Installer operations must be repeatable, parameterizable, and must not write through unrelated symlinks.

## Testing
- Static parsing and linting are necessary but insufficient.
- Test profile loading in fresh PowerShell processes as well as the current process.
- Test destructive commands with -WhatIf.
- Interactive PSReadLine and prompt repaint behavior still require a real terminal smoke test.