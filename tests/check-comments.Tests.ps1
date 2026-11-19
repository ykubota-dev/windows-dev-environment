Describe 'Comment policy lint' {
    BeforeAll {
        $script:lintPath = Join-Path $PSScriptRoot '../scripts/ci/check-comments.ps1'
    }

    It 'accepts code without comments' {
        $caseRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path (Join-Path $caseRoot 'scripts') -Force
        Set-Content -LiteralPath (Join-Path $caseRoot 'scripts/valid.ps1') -Value 'Write-Output "hello"' -Encoding utf8

        & $script:lintPath -Root $caseRoot | Should -Match 'Comment lint passed'
    }

    It 'rejects ordinary comments with a line number' {
        $caseRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path (Join-Path $caseRoot 'scripts') -Force
        Set-Content -LiteralPath (Join-Path $caseRoot 'scripts/invalid.ps1') -Value @('# explanation', 'Write-Output 1') -Encoding utf8

        { & $script:lintPath -Root $caseRoot 3>$null } | Should -Throw '*Comment lint failed (1 violation(s))*'
    }

    It 'does not mistake a hash character inside strings for a comment' {
        $caseRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path (Join-Path $caseRoot 'scripts') -Force
        Set-Content -LiteralPath (Join-Path $caseRoot 'scripts/string.ps1') -Value '$value = "#not-a-comment"' -Encoding utf8

        & $script:lintPath -Root $caseRoot | Should -Match 'Comment lint passed'
    }

    It 'allows a SAFETY comment with an explanation' {
        $caseRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path (Join-Path $caseRoot 'scripts') -Force
        Set-Content -LiteralPath (Join-Path $caseRoot 'scripts/safety.ps1') -Value @('# SAFETY: mandatory external constraint', 'Write-Output 1') -Encoding utf8

        & $script:lintPath -Root $caseRoot | Should -Match 'Comment lint passed'
    }

    It 'rejects a SAFETY marker without justification' {
        $caseRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path (Join-Path $caseRoot 'scripts') -Force
        Set-Content -LiteralPath (Join-Path $caseRoot 'scripts/empty-safety.ps1') -Value '# SAFETY:' -Encoding utf8

        { & $script:lintPath -Root $caseRoot 3>$null } | Should -Throw '*Comment lint failed*'
    }

    It 'rejects block comments' {
        $caseRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path (Join-Path $caseRoot 'tests') -Force
        Set-Content -LiteralPath (Join-Path $caseRoot 'tests/block.Tests.ps1') -Value '<# explanation #>' -Encoding utf8

        { & $script:lintPath -Root $caseRoot 3>$null } | Should -Throw '*Comment lint failed*'
    }

    It 'ignores markdown documentation' {
        $caseRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path (Join-Path $caseRoot 'scripts') -Force
        $null = New-Item -ItemType Directory -Path (Join-Path $caseRoot 'docs') -Force
        Set-Content -LiteralPath (Join-Path $caseRoot 'scripts/valid.ps1') -Value 'Write-Output 1' -Encoding utf8
        Set-Content -LiteralPath (Join-Path $caseRoot 'docs/guide.md') -Value '# Heading' -Encoding utf8

        & $script:lintPath -Root $caseRoot | Should -Match 'Comment lint passed'
    }

    It 'rejects empty source directories' {
        $caseRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path $caseRoot

        { & $script:lintPath -Root $caseRoot } | Should -Throw '*No PowerShell files found*'
    }
}
