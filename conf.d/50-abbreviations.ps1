# Short command names for common terminal work.
Set-Alias -Name c -Value Set-Location
Set-Alias -Name h -Value Get-History
Set-Alias -Name which -Value Get-Command

function g  { git @args }
function gs { git status --short --branch @args }
function ga { git add @args }
function gco { git switch @args }
function gcb { git switch -c @args }
function gcm { git commit @args }
function gpl { git pull --ff-only @args }
function gps { git push @args }
function glog { git log --oneline --graph --decorate @args }

function v {
    if (Get-Command nvim -ErrorAction SilentlyContinue) {
        nvim @args
    } else {
        throw 'nvim is not on PATH.'
    }
}

function nvg {
    if (Get-Command neovide -ErrorAction SilentlyContinue) {
        neovide --frame none @args
    } else {
        throw 'neovide is not on PATH.'
    }
}
