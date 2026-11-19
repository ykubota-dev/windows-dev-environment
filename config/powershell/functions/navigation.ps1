function croot {
    $command = Get-Command git -ErrorAction SilentlyContinue
    if (-not $command) { Write-Warning 'Gitが見つかりません。'; return }
    $rootPath = & git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $rootPath) { Write-Warning 'Gitリポジトリ外です。'; return }
    Set-Location -LiteralPath $rootPath
}

function mkcd {
    param([Parameter(Mandatory, Position = 0)][string]$Path)
    if (Test-Path -LiteralPath $Path -PathType Leaf) { throw "ファイルが存在します: $Path" }
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $Path -Force -ErrorAction Stop
    }
    Set-Location -LiteralPath $Path
}
