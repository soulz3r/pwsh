# One plain prompt. No theme engine, segments, symbols, or Git probes.
function global:prompt {
    "$((Get-Location).Path) ❯ "
}
