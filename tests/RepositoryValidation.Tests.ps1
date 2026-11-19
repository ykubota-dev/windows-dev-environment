Describe 'Repository syntax validation' {
    It 'accepts valid PowerShell and JSON files' {
        $validatorPath = Join-Path $PSScriptRoot '../scripts/ci/validate-repository.ps1'
        $caseRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path $caseRoot
        Set-Content -LiteralPath (Join-Path $caseRoot 'valid.ps1') -Value 'Write-Output "hello"' -Encoding utf8
        Set-Content -LiteralPath (Join-Path $caseRoot 'valid.json') -Value '{"name":"example","enabled":true}' -Encoding utf8

        & $validatorPath -Root $caseRoot | Should -Match 'validation passed'
    }

    It 'rejects invalid PowerShell syntax' {
        $validatorPath = Join-Path $PSScriptRoot '../scripts/ci/validate-repository.ps1'
        $caseRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path $caseRoot
        Set-Content -LiteralPath (Join-Path $caseRoot 'invalid.ps1') -Value 'function Test-Invalid {' -Encoding utf8

        { & $validatorPath -Root $caseRoot } | Should -Throw '*validation failed*'
    }

    It 'rejects malformed JSON' {
        $validatorPath = Join-Path $PSScriptRoot '../scripts/ci/validate-repository.ps1'
        $caseRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path $caseRoot
        Set-Content -LiteralPath (Join-Path $caseRoot 'invalid.json') -Value '{"name":}' -Encoding utf8

        { & $validatorPath -Root $caseRoot } | Should -Throw '*validation failed*'
    }

    It 'rejects directories without source files' {
        $validatorPath = Join-Path $PSScriptRoot '../scripts/ci/validate-repository.ps1'
        $caseRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path $caseRoot
        { & $validatorPath -Root $caseRoot } | Should -Throw '*No PowerShell or JSON files*'
    }
}
