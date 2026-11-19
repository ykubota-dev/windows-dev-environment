$functionDirectory = Join-Path $PSScriptRoot 'functions'
foreach ($file in @('navigation.ps1', 'filesystem.ps1', 'diagnostics.ps1', 'git.ps1')) {
    . (Join-Path $functionDirectory $file)
}
