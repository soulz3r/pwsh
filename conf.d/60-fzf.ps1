$env:FZF_DEFAULT_OPTS = @'
--height=40%
--layout=reverse
--border=rounded
--padding=1
--info=inline
--prompt='❯ '
--pointer='▶'
--marker='✓'
'@

if (Get-Module -ListAvailable -Name PSFzf) {
    Import-Module PSFzf -ErrorAction SilentlyContinue

    if (Get-Command Set-PsFzfOption -ErrorAction SilentlyContinue) {
        Set-PsFzfOption `
            -PSReadlineChordProvider 'Ctrl+t' `
            -PSReadlineChordReverseHistory 'Ctrl+r' `
            -PSReadlineChordSetLocation 'Alt+c'
    }
}
