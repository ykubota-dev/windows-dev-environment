# Terminal-facing prompts are intentionally written to the host, not the success pipeline.
# Keep this suppression local to the interactive setup entry point.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Interactive terminal UI intentionally writes prompts and status messages to the host.')]
[CmdletBinding()]
param(
    [string[]]$Features,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$featureCatalog = [ordered]@{
    F01 = @{ Name = 'クリップボード履歴'; Plan = '現在状態を確認し、必要ならWindowsのGUI操作を案内します（自動変更なし）。' }
    F02 = @{ Name = 'PowerToys'; Plan = 'PowerToysの導入状況を確認し、Run / FancyZonesを設定します（現段階では手動操作）。' }
    F03 = @{ Name = 'PowerShell / Git エイリアス'; Plan = 'PowerShellプロファイルとGitエイリアスの変更予定を確認します。' }
    F04 = @{ Name = 'VS Code 設定同期'; Plan = 'VS Codeの設定同期を有効にします（現段階では手動操作）。' }
    F05 = @{ Name = 'winget パッケージ'; Plan = 'wingetによるパッケージ導入予定を確認します。現段階ではインストールしません。' }
}

function Resolve-FeatureSelection {
    param(
        [string[]]$Requested,
        [System.Collections.IDictionary]$Catalog
    )

    $tokens = @(
        foreach ($entry in $Requested) {
            foreach ($token in ($entry -split ',')) {
                $token.Trim().ToUpperInvariant()
            }
        }
    )

    if ($tokens.Count -eq 0 -or @($tokens | Where-Object { $_ -eq '' }).Count -gt 0) {
        throw '有効な機能IDを1つ以上選択してください。'
    }

    if ($tokens -contains 'ALL') {
        if ($tokens.Count -ne 1) {
            throw 'Allと個別の機能IDは同時に指定できません。'
        }
        return @($Catalog.Keys)
    }

    $unknown = @($tokens | Where-Object { -not $Catalog.Contains($_) })
    if ($unknown.Count -gt 0) {
        throw "不明な機能ID: $($unknown -join ', ')"
    }

    return @($Catalog.Keys | Where-Object { $tokens -contains $_ })
}

Write-Host '=== Windows開発環境セットアップ ==='
Write-Host 'F01は状態確認と操作案内に対応しています。Windows設定やファイルの変更、パッケージ導入は行いません。'
Write-Host ''

foreach ($id in $featureCatalog.Keys) {
    Write-Host ("{0}  {1}" -f $id, $featureCatalog[$id].Name)
}
Write-Host ''

if (-not $Features -or $Features.Count -eq 0) {
    if ($DryRun) {
        throw '-DryRunを使う場合は-Featuresで機能を指定してください。'
    }
    $Features = @(Read-Host '機能IDを選択（例: F01,F03 / 全選択: All / 終了: Cancel）')
}

if ($Features.Count -eq 1 -and $Features[0].Trim() -match '^(?i:cancel)$') {
    Write-Host '中止しました。変更は行っていません。'
    return
}

$selected = @(Resolve-FeatureSelection -Requested $Features -Catalog $featureCatalog)

Write-Host '=== 実行予定の内容 ==='
foreach ($id in $selected) {
    Write-Host ("[{0}] {1}" -f $id, $featureCatalog[$id].Name)
    Write-Host ("  予定: {0}" -f $featureCatalog[$id].Plan)
    if ($id -eq 'F01') { Write-Host '  状態: 状態確認・操作案内に対応' }
    else { Write-Host '  状態: 未実装（プレビューのみ）' }
}
Write-Host ''

if ($DryRun) {
    Write-Host 'DryRunが完了しました。変更は行っていません。'
    return
}

$results = [System.Collections.Generic.List[object]]::new()
foreach ($id in $selected) {
    $decision = (Read-Host "[$id] 実行予定を確認しましたか？ [Yes: 確認 / Skip: スキップ / Cancel: 全体中止]").Trim()
    switch -Regex ($decision) {
        '^(?i:yes|y)$' {
            if ($id -eq 'F01') {
                $featureScript = Join-Path $PSScriptRoot 'features/F01-clipboard.ps1'
                try {
                    $featureResult = & $featureScript
                    $results.Add($featureResult)
                }
                catch {
                    $results.Add([pscustomobject]@{
                            FeatureId = $id
                            Status = 'Failed'
                            Message = "F01の実行に失敗しました: $($_.Exception.Message)"
                        })
                }
            }
            else {
                $results.Add([pscustomobject]@{
                        FeatureId = $id
                        Status = 'ManualRequired'
                        Message = '機能の適用処理は未実装です。変更は行っていません。'
                    })
            }
            break
        }
        '^(?i:cancel|c)$' {
            Write-Host '中止しました。残りの機能は処理していません。'
            break
        }
        default {
            $results.Add([pscustomobject]@{
                    FeatureId = $id
                    Status = 'Skipped'
                    Message = '確認をスキップしました。変更は行っていません。'
                })
        }
    }

    if ($decision -match '^(?i:cancel|c)$') {
        break
    }
}

Write-Host '=== 確認結果 ==='
foreach ($result in $results) {
    Write-Host ("{0}: {1} - {2}" -f $result.FeatureId, $result.Status, $result.Message)
}
Write-Host '変更は行っていません。'
