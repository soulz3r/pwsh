# Design

Keep the shell predictable and small.

- Oh My Posh owns prompt rendering and live Vi-mode redraw.
- The prompt shows only path, local Git state, Vi mode, and the input arrow.
- Git status is local-only; never query remotes while rendering the prompt.
- PSReadLine owns Vi editing.
- zoxide is optional and initialized after the prompt.
- Shortcuts are small aliases/functions that pass arguments through unchanged.
- Avoid prompt-time filesystem scans, plugin frameworks, and duplicate command wrappers.
