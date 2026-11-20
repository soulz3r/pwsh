# Small, predictable shortcuts.
Set-Alias -Name c -Value Set-Location
Set-Alias -Name which -Value Get-Command
Set-Alias -Name vi -Value vim

function g    { git @args }
function gs   { git status --short --branch @args }
function ga   { git add @args }
function gco  { git switch @args }
function gcb  { git switch -c @args }
function gcm  { git commit @args }
function gpl  { git pull --ff-only @args }
function gps  { git push @args }
function glog { git log --oneline --graph --decorate @args }

function v {
    $editor = Get-Command vim -CommandType Application -ErrorAction SilentlyContinue
    if (-not $editor) { throw 'vim is not on PATH.' }
    & $editor.Source @args
}
