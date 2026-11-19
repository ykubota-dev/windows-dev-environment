BeforeAll {
    $validatorPath = Join-Path $PSScriptRoot '../scripts/ci/validate-repository.ps1'
}

Describe 'Repository syntax validation' {
    It 'accepts valid PowerShell and JSON files' {
        Set-Content -LiteralPath (Join-Path $TestDrive 'valid.ps1') -Value 'Write-Output "hello"' -Encoding utf8
        Set-Content -LiteralPath (Join-Path $TestDrive 'valid.json') -Value '{"name":"example","enabled":true}' -Encoding utf8

        & $validatorPath -Root $TestDrive | Should -Match 'validation passed'
    }

    It 'rejects invalid PowerShell syntax' {
        Set-Content -LiteralPath (Join-Path $TestDrive 'invalid.ps1') -Value 'function Test-Invalid {' -Encoding utf8

        { & $validatorPath -Root $TestDrive } | Should -Throw '*validation failed*'
    }

    It 'rejects malformed JSON' {
        Set-Content -LiteralPath (Join-Path $TestDrive 'invalid.json') -Value '{"name":}' -Encoding utf8

        { & $validatorPath -Root $TestDrive } | Should -Throw '*validation failed*'
    }

    It 'rejects directories without source files' {
        { & $validatorPath -Root $TestDrive } | Should -Throw '*No PowerShell or JSON files*'
    }
}
