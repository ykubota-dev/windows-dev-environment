Describe 'F02 Git Alias' {
    BeforeAll {
        $script:featurePath = Join-Path $PSScriptRoot '../scripts/features/F02-git-alias.ps1'
        . $script:featurePath
    }

    BeforeEach {
        $script:tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString('N'))
        $null = New-Item -Path $script:tempRoot -ItemType Directory
        $script:globalConfig = Join-Path $script:tempRoot '.gitconfig'
        $script:managedConfig = Join-Path $script:tempRoot 'managed/aliases.gitconfig'
    }

    AfterEach {
        Remove-Item -LiteralPath $script:tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'does not create files in DryRun' {
        $result = Invoke-F02GitAlias -DryRun -GitConfigPath $script:globalConfig -ManagedConfigPath $script:managedConfig
        $result.Status | Should -Be 'Skipped'
        Test-Path -LiteralPath $script:globalConfig | Should -BeFalse
        Test-Path -LiteralPath $script:managedConfig | Should -BeFalse
    }

    It 'creates a managed include after explicit approval' {
        Mock Read-Host { 'Yes' }
        $result = Invoke-F02GitAlias -GitConfigPath $script:globalConfig -ManagedConfigPath $script:managedConfig
        $result.Status | Should -Be 'Success'
        (Get-Content -LiteralPath $script:managedConfig -Raw) | Should -Match 'st = status'
        $includes = @(& git config --file $script:globalConfig --get-all include.path)
        $includes | Should -Contain $script:managedConfig
    }

    It 'is idempotent on a second run' {
        Mock Read-Host { 'Yes' }
        $null = Invoke-F02GitAlias -GitConfigPath $script:globalConfig -ManagedConfigPath $script:managedConfig
        $result = Invoke-F02GitAlias -GitConfigPath $script:globalConfig -ManagedConfigPath $script:managedConfig
        $result.Status | Should -Be 'Skipped'
        @(& git config --file $script:globalConfig --get-all include.path).Count | Should -Be 1
    }

    It 'does not overwrite an existing conflicting alias' {
        & git config --file $script:globalConfig alias.st 'status --short'
        $result = { Invoke-F02GitAlias -GitConfigPath $script:globalConfig -ManagedConfigPath $script:managedConfig }
        $result | Should -Throw '*競合*'
        Test-Path -LiteralPath $script:managedConfig | Should -BeFalse
    }

    It 'does not modify files when approval is skipped' {
        Mock Read-Host { 'Skip' }
        $result = Invoke-F02GitAlias -GitConfigPath $script:globalConfig -ManagedConfigPath $script:managedConfig
        $result.Status | Should -Be 'Skipped'
        Test-Path -LiteralPath $script:managedConfig | Should -BeFalse
    }

    It 'backs up existing global config before adding include' {
        & git config --file $script:globalConfig user.name 'Test User'
        Mock Read-Host { 'Yes' }
        $result = Invoke-F02GitAlias -GitConfigPath $script:globalConfig -ManagedConfigPath $script:managedConfig
        $result.Status | Should -Be 'Success'
        @(Get-ChildItem -LiteralPath $script:tempRoot -Filter '*.bak').Count | Should -Be 1
    }
}
