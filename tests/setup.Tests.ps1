Describe 'Setup controller (registered features only)' {
    BeforeAll {
        $script:setupPath = Join-Path $PSScriptRoot '../scripts/setup.ps1'
    }

    It 'shows plans without changing the machine in DryRun mode' {
        $output = & $script:setupPath -Features F01 -DryRun 6>&1 | Out-String
        $output | Should -Match '\[F01\]'
        $output | Should -Match 'DryRunが完了しました'
        $output | Should -Not -Match '\[F02\]'
    }

    It 'supports All in catalog order' {
        $output = & $script:setupPath -Features All -DryRun 6>&1 | Out-String
        $output | Should -Match '\[F01\]'
        $output | Should -Match '\[F02\]'
        $output | Should -Match '\[F03\]'
        $planMatch = [regex]::Match($output, '(?ms)=== 実行予定の内容 ===\r?\n(.*?)\r?\n[ \t]*\r?\n')
        $planMatch.Success | Should -BeTrue
        $featureMatches = [regex]::Matches($planMatch.Groups[1].Value, '(?m)^\[(F0[1-3])\]')
        @($featureMatches | ForEach-Object { $_.Groups[1].Value }) -join ',' | Should -Be 'F01,F02,F03'
    }

    It 'rejects the next unimplemented feature ID' {
        { & $script:setupPath -Features F04 -DryRun 6>&1 } | Should -Throw '*不明な機能ID*'
    }

    It 'shows only registered features in the selection menu' {
        $output = & $script:setupPath -Features F01 -DryRun 6>&1 | Out-String
        $output | Should -Match 'F01  クリップボード履歴'
        $output | Should -Match 'F02  Git Alias'
        $output | Should -Match 'F03  PowerShell Profile'
        $menu = [regex]::Matches($output, '(?m)^(F0[1-3])  ')
        @($menu | ForEach-Object { $_.Groups[1].Value }) -join ',' | Should -Be 'F01,F02,F03'
    }

    It 'rejects unrecognized feature IDs' {
        { & $script:setupPath -Features F99 -DryRun 6>&1 } | Should -Throw '*不明な機能ID*'
    }

    It 'rejects mixing All and a feature' {
        { & $script:setupPath -Features All,F01 -DryRun 6>&1 } | Should -Throw '*同時に指定できません*'
    }

    It 'requires explicit feature selection in non-interactive DryRun mode' {
        { & $script:setupPath -DryRun 6>&1 } | Should -Throw '*-Featuresで機能を指定してください*'
    }

    It 'allows cancellation without modifying anything' {
        $output = & $script:setupPath -Features Cancel 6>&1 | Out-String
        $output | Should -Match '中止しました。変更は行っていません。'
    }
}
