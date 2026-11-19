function touch {
    param([Parameter(Mandatory, Position = 0)][string]$Path)
    if (Test-Path -LiteralPath $Path -PathType Container) { throw "ディレクトリは指定できません: $Path" }
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        (Get-Item -LiteralPath $Path).LastWriteTime = Get-Date
    }
    else {
        $parent = Split-Path -Parent $Path
        if ($parent -and -not (Test-Path -LiteralPath $parent -PathType Container)) {
            throw "親ディレクトリが存在しません: $parent"
        }
        $null = New-Item -ItemType File -Path $Path -ErrorAction Stop
    }
}

function findtext {
    param(
        [Parameter(Mandatory, Position = 0)][string]$Text,
        [Parameter(Position = 1)][string]$Path = '.'
    )
    if (-not (Test-Path -LiteralPath $Path)) { throw "パスが存在しません: $Path" }
    $excluded = @('.git', 'node_modules', '.venv')
    $files = @(if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Get-Item -LiteralPath $Path
    } else {
        Get-ChildItem -LiteralPath $Path -Recurse -File -ErrorAction Stop |
            Where-Object {
                $relative = [System.IO.Path]::GetRelativePath((Resolve-Path -LiteralPath $Path).Path, $_.FullName)
                -not @($relative -split '[\\/]' | Where-Object { $_ -in $excluded }).Count
            }
    })
    foreach ($file in $files) {
        Select-String -LiteralPath $file.FullName -SimpleMatch -Pattern $Text -ErrorAction SilentlyContinue |
            Select-Object Path, LineNumber, Line
    }
}
