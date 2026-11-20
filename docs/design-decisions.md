# Design

Keep this profile small and predictable.

- PowerShell owns the prompt. It shows only the current path and input arrow.
- PSReadLine owns Vi editing and the cursor indicator.
- zoxide is optional and initialized only when installed.
- Shortcuts are plain aliases or functions. No abbreviation engine or custom completion framework.
- External tools are optional; the profile still loads without them.
- Avoid prompt-time Git or filesystem scans.
- Prefer native PowerShell commands over wrappers unless a shortcut is genuinely useful.
