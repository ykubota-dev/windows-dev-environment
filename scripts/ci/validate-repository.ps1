# Validate PowerShell parser errors and JSON formatting without modifying files.
[CmdletBinding()]
param(
    [Parameter()]
    [string]$Root = (Join-Path $PSScriptRoot '../..')
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = (Resolve-Path -LiteralPath $Root -ErrorAction Stop).Path

if (-not (Test-Path -LiteralPath $repositoryRoot -PathType Container)) {
    throw "Not a directory: $repositoryRoot"
}

$sourceFiles = @(
    Get-ChildItem -LiteralPath $repositoryRoot -Recurse -File |
        Where-Object {
            $_.Extension -in @('.ps1', '.psm1', '.psd1', '.json') -and
            $_.FullName -notmatch '[\\/](\.git|\.backups|backups|logs)[\\/]'
        }
)

if ($sourceFiles.Count -eq 0) {
    throw "No PowerShell or JSON files found under $repositoryRoot"
}

$failures = [System.Collections.Generic.List[string]]::new()

foreach ($file in $sourceFiles) {
    if ($file.Extension -eq '.json') {
        try {
            $null = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction Stop |
                ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            $failures.Add("JSON: $($file.FullName): $($_.Exception.Message)")
        }
        continue
    }

    $tokens = $null
    $parseErrors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile(
        $file.FullName,
        [ref]$tokens,
        [ref]$parseErrors
    )

    foreach ($parseError in $parseErrors) {
        $failures.Add("PowerShell: $($file.FullName): line $($parseError.Extent.StartLineNumber): $($parseError.Message)")
    }
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        Write-Warning $failure
    }
    throw "Repository validation failed ($($failures.Count) error(s))."
}

Write-Output "Repository validation passed ($($sourceFiles.Count) file(s))."
