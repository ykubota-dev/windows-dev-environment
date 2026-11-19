Describe 'F03 PowerShell 7 Profile' {
    BeforeAll {
        $script:featurePath = Join-Path $PSScriptRoot '../scripts/features/F03-powershell-profile.ps1'
        . $script:featurePath
    }
    BeforeEach {
        $script:tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString('N'))
        $null = New-Item -Path $script:tempRoot -ItemType Directory
        $script:profilePath = Join-Path $script:tempRoot 'Microsoft.PowerShell_profile.ps1'
        $script:managedPath = Join-Path $script:tempRoot 'managed'
    }
    AfterEach {
        Remove-Item -LiteralPath $script:tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    It 'does not create files during DryRun' {
        $result = Invoke-F03PowerShellProfile -DryRun -ProfilePath $script:profilePath -ManagedDirectory $script:managedPath
        $result.Status | Should -Be 'Skipped'
        Test-Path -LiteralPath $script:profilePath | Should -BeFalse
        Test-Path -LiteralPath $script:managedPath | Should -BeFalse
    }
    It 'creates profile and managed functions after approval' {
        Mock Read-Host { 'Yes' }
        $result = Invoke-F03PowerShellProfile -ProfilePath $script:profilePath -ManagedDirectory $script:managedPath
        $result.Status | Should -Be 'Success'
        (Get-Content -LiteralPath $script:profilePath -Raw) | Should -Match 'BEGIN windows-dev-environment F03'
        Test-Path -LiteralPath (Join-Path $script:managedPath 'functions/git.ps1') | Should -BeTrue
    }
    It 'preserves existing profile and creates a backup' {
        Set-Content -LiteralPath $script:profilePath -Value '$customSetting = 42'
        Mock Read-Host { 'Yes' }
        $result = Invoke-F03PowerShellProfile -ProfilePath $script:profilePath -ManagedDirectory $script:managedPath
        $result.Status | Should -Be 'Success'
        (Get-Content -LiteralPath $script:profilePath -Raw) | Should -Match '\$customSetting = 42'
        @(Get-ChildItem -LiteralPath $script:tempRoot -Filter '*.bak').Count | Should -Be 1
    }
    It 'is idempotent' {
        Mock Read-Host { 'Yes' }
        $null = Invoke-F03PowerShellProfile -ProfilePath $script:profilePath -ManagedDirectory $script:managedPath
        $result = Invoke-F03PowerShellProfile -ProfilePath $script:profilePath -ManagedDirectory $script:managedPath
        $result.Status | Should -Be 'Skipped'
    }
    It 'does not write when skipped' {
        Mock Read-Host { 'Skip' }
        $result = Invoke-F03PowerShellProfile -ProfilePath $script:profilePath -ManagedDirectory $script:managedPath
        $result.Status | Should -Be 'Skipped'
        Test-Path -LiteralPath $script:profilePath | Should -BeFalse
    }
    It 'rejects malformed managed markers' {
        Set-Content -LiteralPath $script:profilePath -Value '# BEGIN windows-dev-environment F03'
        { Invoke-F03PowerShellProfile -DryRun -ProfilePath $script:profilePath -ManagedDirectory $script:managedPath } |
            Should -Throw '*管理ブロックが不正*'
    }
}

Describe 'F03 functions' {
    BeforeAll {
        . (Join-Path $PSScriptRoot '../config/powershell/profile.ps1')
    }
    BeforeEach {
        $script:originalLocation = Get-Location
        $script:tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString('N'))
        $null = New-Item -Path $script:tempRoot -ItemType Directory
        Set-Location -LiteralPath $script:tempRoot
    }
    AfterEach {
        Set-Location -LiteralPath $script:originalLocation.Path
        Remove-Item -LiteralPath $script:tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    It 'mkcd creates and enters directory' {
        mkcd 'new folder'
        (Get-Location).Path | Should -Be (Join-Path $script:tempRoot 'new folder')
    }
    It 'touch creates a file without overwriting its contents' {
        touch 'example.txt'
        Set-Content -LiteralPath 'example.txt' -Value 'keep'
        touch 'example.txt'
        Get-Content -LiteralPath 'example.txt' | Should -Be 'keep'
    }
    It 'findtext finds literal matches' {
        Set-Content -LiteralPath 'sample.txt' -Value 'a.b'
        $result = @(findtext 'a.b' '.')
        $result.Count | Should -Be 1
        $result[0].LineNumber | Should -Be 1
    }
    It 'gbranch cancels without changing branches' {
        & git init -q
        & git -c user.name=Test -c user.email=test@example.com commit --allow-empty -m initial -q
        & git branch test-branch
        $before = & git branch --show-current
        Mock Read-Host { '' }
        gbranch
        (& git branch --show-current) | Should -Be $before
    }
    It 'gbranch switches by selected number' {
        & git init -q
        & git -c user.name=Test -c user.email=test@example.com commit --allow-empty -m initial -q
        & git branch test-branch
        Mock Read-Host { '1' }
        $branches = @(& git for-each-ref --format='%(refname:short)' refs/heads)
        gbranch
        (& git branch --show-current) | Should -Be $branches[0]
    }
}
