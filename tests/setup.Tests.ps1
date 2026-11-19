Describe 'Setup controller (preview only)' {
    BeforeAll {
        $script:setupPath = Join-Path $PSScriptRoot '../scripts/setup.ps1'
    }

    It 'shows plans without changing the machine in DryRun mode' {
        $output = & $script:setupPath -Features F01,F03 -DryRun 6>&1 | Out-String
        $output | Should -Match '\[F01\]'
        $output | Should -Match '\[F03\]'
        $output | Should -Match 'DryRunが完了しました'
        $output | Should -Not -Match '\[F02\].*Plan:'
    }

    It 'supports All in catalog order' {
        $output = & $script:setupPath -Features All -DryRun 6>&1 | Out-String
        foreach ($id in @('F01', 'F02', 'F03', 'F04', 'F05')) {
            $output | Should -Match ([regex]::Escape("[$id]"))
        }
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
