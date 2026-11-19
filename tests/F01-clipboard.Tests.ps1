Describe 'F01 クリップボード履歴' {
    BeforeAll {
        $script:f01Path = Join-Path $PSScriptRoot '../scripts/features/F01-clipboard.ps1'
        . $script:f01Path
    }

    It 'DryRunでは設定を変更せずSkippedを返す' {
        $result = Invoke-F01ClipboardHistory -DryRun 6>$null
        $result.FeatureId | Should -Be 'F01'
        $result.Status | Should -Be 'Skipped'
    }

    It '有効な場合はSuccessを返す' {
        Mock Get-F01ClipboardHistoryState { 'Enabled' }
        $result = Invoke-F01ClipboardHistory 6>$null
        $result.Status | Should -Be 'Success'
    }

    It '無効な場合は手動操作を案内する' {
        Mock Get-F01ClipboardHistoryState { 'Disabled' }
        $output = Invoke-F01ClipboardHistory 6>&1
        ($output | Where-Object { $_ -is [string] } | Out-String) | Should -Match 'Win \+ V'
        ($output | Where-Object { $_ -isnot [string] }).Status | Should -Be 'ManualRequired'
    }

    It '判定できない場合は有効と推測しない' {
        Mock Get-F01ClipboardHistoryState { 'Unknown' }
        $result = Invoke-F01ClipboardHistory 6>$null
        $result.Status | Should -Be 'ManualRequired'
    }

    It '状態取得APIが例外を出しても手動操作を案内する' {
        Mock Get-F01ClipboardHistoryState { throw 'API error' }
        $result = Invoke-F01ClipboardHistory 6>$null
        $result.Status | Should -Be 'ManualRequired'
    }
}
