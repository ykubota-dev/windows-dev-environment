[CmdletBinding()]
param(
    [string]$Root = (Join-Path $PSScriptRoot '../..')
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = (Resolve-Path -LiteralPath $Root -ErrorAction Stop).Path
$scanRoots = @('scripts', 'tests')
$files = @(
    foreach ($relativePath in $scanRoots) {
        $directory = Join-Path $repositoryRoot $relativePath
        if (Test-Path -LiteralPath $directory -PathType Container) {
            Get-ChildItem -LiteralPath $directory -Recurse -File |
                Where-Object { $_.Extension -in @('.ps1', '.psm1', '.psd1') }
        }
    }
)

if ($files.Count -eq 0) {
    throw "No PowerShell files found in scripts/ or tests/ under $repositoryRoot"
}

$violations = [System.Collections.Generic.List[string]]::new()

foreach ($file in $files) {
    $tokens = $null
    $parseErrors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile(
        $file.FullName,
        [ref]$tokens,
        [ref]$parseErrors
    )

    foreach ($parseError in $parseErrors) {
        $violations.Add(("{0}:{1}: Parse error: {2}" -f $file.FullName, $parseError.Extent.StartLineNumber, $parseError.Message))
    }

    foreach ($token in $tokens) {
        if ($token.Kind -ne 'Comment') {
            continue
        }

        $value = $token.Text.Trim()
        if ($value -match '(?s)^#\s*SAFETY:\s*\S' -or
            $value -match '(?s)^<#\s*SAFETY:\s*\S') {
            continue
        }

        $violations.Add(("{0}:{1}: コメントは禁止です。意図は関数名・変数名・型・テストで表現してください。コードで表現できない安全上の根拠のみ SAFETY: を使用できます。" -f $file.FullName, $token.Extent.StartLineNumber))
    }
}

if ($violations.Count -gt 0) {
    foreach ($violation in $violations) {
        Write-Warning $violation
    }
    throw "Comment lint failed ($($violations.Count) violation(s))."
}

Write-Output "Comment lint passed ($($files.Count) file(s))."
