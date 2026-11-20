# Small filesystem helpers. Keep native Get-ChildItem aliases intact.
function ll {
    Get-ChildItem @args | Format-Table -AutoSize
}

function la {
    Get-ChildItem -Force @args
}

function touch {
    param([Parameter(Mandatory, ValueFromRemainingArguments)][string[]]$Path)
    foreach ($item in $Path) {
        if (Test-Path -LiteralPath $item) {
            (Get-Item -LiteralPath $item).LastWriteTime = Get-Date
        } else {
            New-Item -ItemType File -Path $item -Force | Out-Null
        }
    }
}
