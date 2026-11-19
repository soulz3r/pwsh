# Design decisions

This is a personal interactive shell configuration, not a general-purpose PowerShell framework. Keep moving parts low and integration boundaries explicit.

## Ownership

- PSReadLine owns line editing, Vi keymaps, history, predictions, and its indicator mode.
- Oh My Posh's vimode segment owns the live Vi-mode change handler and prompt repaint.
- The theme owns visual presentation only.
- If Oh My Posh cannot initialize, restore PSReadLine's cursor indicator instead of leaving the user with no mode feedback.
- Optional executables and modules must never be required for profile startup.

## Prompt

- Use a left-aligned two-line prompt with a width-limited folder-aware path and a compact Git context. Keep the Vi indicator beside the input symbol; do not use a far-right prompt for essential state.
- Show the current path, branch, and local staged/working-tree state.
- Do not calculate remote ahead/behind counts on every prompt render.
- Keep command duration visible only when it is useful, with a restrained indicator and a one-second threshold.
- Use the current Oh My Posh config format and test the prompt's structural expectations.

## Startup

- The root profile resolves its symlink before locating conf.d.
- Components load in lexical order; failures identify the component that failed.
- Components that register global callbacks must be safe to dot-source repeatedly.
- On profile reload, restore the underlying prompt before Oh My Posh initializes, then reinstall zoxide's wrapper around the fresh prompt.
- Use zoxide's change-aware PWD hook on modern PowerShell to avoid running a database update on every prompt.

## Navigation and search

- Prefer fd for filesystem traversal and retain a bounded PowerShell fallback.
- Stream file candidates directly from fd (or the PowerShell fallback) into fzf instead of materializing the entire file list first.
- fzf owns selection; candidate discovery belongs to the producing command.
- Exclude generated/vendor directories by default and do not follow directory symlinks.
- Project discovery recognizes common build-system and version-control markers.
- Resolve search roots before handing them to external tools so spaces and relative paths behave consistently.
- Treat empty roots and missing dependencies as explicit errors, not silent no-ops.

## Filesystem safety

- Keep recursive deletion behind the rdtree implementation with WhatIf and Confirm support.
- Preserve the original profile's rmdir shortcut as an alias to rdtree for command compatibility.
- Listing commands retain useful native fallbacks when lsd is absent.
- The ls function must not be shadowed by the built-in alias.
- Tree fallbacks use readable branch connectors, obey a depth limit, skip generated folders, and never recurse through directory links.

## Environment and optional tools

- Preserve user-provided environment options; append FZF defaults rather than replacing them.
- Assign environment defaults only when the user has not already set them.
- Optional integrations should be idempotent and report initialization failures without breaking unrelated commands.
- Installer operations must be repeatable, parameterizable, and must not write through unrelated symlinks.

## Testing

- Static parsing and linting are necessary but insufficient.
- Test command resolution, not just the existence of a function with the same name.
- Test profile loading in fresh PowerShell processes as well as the current process, including prompt-hook state after repeated dot-sourcing.
- Test destructive commands with WhatIf and against disposable directories.
- Exercise bounded search and tree fallbacks without requiring fd, fzf, or lsd.
- Interactive PSReadLine and prompt repaint behavior still require a real terminal smoke test.
