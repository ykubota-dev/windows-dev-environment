[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = '対話型CLIの案内を成功パイプラインと分離するため。')]
[CmdletBinding()]
param([switch]$DryRun)

function Get-F01ClipboardHistoryState {
    [CmdletBinding()]
    param()

    if ($PSVersionTable.PSEdition -eq 'Core' -and -not $IsWindows) {
        return 'Unknown'
    }

    try {

        $clipboardType = [Windows.ApplicationModel.DataTransfer.Clipboard, Windows.ApplicationModel.DataTransfer, ContentType=WindowsRuntime]
        if ($clipboardType::IsHistoryEnabled()) {
            return 'Enabled'
        }
        return 'Disabled'
    }
    catch {
        return 'Unknown'
    }
}

function Invoke-F01ClipboardHistory {
    [CmdletBinding()]
    param([switch]$DryRun)

    if ($DryRun) {
        Write-Host '[F01] クリップボード履歴の状態確認とGUI操作案内を予定しています。'
        Write-Host '  DryRun: Windows設定は変更しません。'
        return [pscustomobject]@{ FeatureId = 'F01'; Status = 'Skipped'; Message = 'DryRun: 状態確認と案内のみを予定しています。' }
    }

    try {
        $state = Get-F01ClipboardHistoryState
    }
    catch {
        $state = 'Unknown'
    }
    if ($state -eq 'Enabled') {
        Write-Host '[F01] クリップボード履歴は有効です。変更は不要です。'
        return [pscustomobject]@{ FeatureId = 'F01'; Status = 'Success'; Message = 'クリップボード履歴が有効であることを確認しました。' }
    }

    if ($state -eq 'Disabled') {
        Write-Host '[F01] クリップボード履歴は無効です。'
    }
    else {
        Write-Host '[F01] クリップボード履歴の状態は未確認です。'
    }
    Write-Host '  1. Win + V を押します。'
    Write-Host '  2. 「有効にする」が表示された場合は選択します。'
    Write-Host '  3. または「設定」→「システム」→「クリップボード」→「クリップボードの履歴」を確認します。'
    Write-Host '  ※ 本ツールはWindows設定を自動変更しません。組織の制限がある場合は管理者に確認してください。'
    return [pscustomobject]@{ FeatureId = 'F01'; Status = 'ManualRequired'; Message = 'Win + V またはWindows設定から確認・有効化してください。' }
}

if ($MyInvocation.InvocationName -ne '.') {
    Invoke-F01ClipboardHistory -DryRun:$DryRun
}
