# CI ガイド

## 目的

Windows開発環境向けPowerShellコードを追加する前に、Pull Requestで品質を自動検証する。**CIではセットアップスクリプトやwingetによる環境変更を実行しない。**

## トリガーとジョブ

- `main` 向けPull Request（作成・更新）
- `main` へのpush
- GitHubホストの `windows-latest` ランナー
- 単一の `PowerShell quality` ジョブ
- リポジトリ権限は `contents: read` のみに制限

検証内容：

1. PowerShell 7上でPSScriptAnalyzer 1.25.0 / Pester 5.9.0を導入
2. PowerShell (`.ps1`, `.psm1`, `.psd1`) の構文検証、および `.json` の解析
3. コメント禁止Lintによる `scripts/` と `tests/` のチェック
4. PSScriptAnalyzerによる `scripts/` と `tests/` のError/Warningチェック
5. Pesterによる `tests/*.Tests.ps1` の単体テスト

構文チェックは `scripts/ci/validate-repository.ps1` が実施する。構文・JSONが不正な場合にゼロ以外の終了コードで失敗し、CI全体も失敗する。

**注意：** CIの静的解析や単体テストは、実機上の設定変更の安全性を保証するものではない。機能別の単体テストとWindows実機確認を今後追加する。

## ローカル実行（PowerShell 7）

リポジトリルートで以下を実行する。

```powershell
Install-Module PSScriptAnalyzer -RequiredVersion 1.25.0 -Scope CurrentUser -Force
Install-Module Pester -RequiredVersion 5.9.0 -Scope CurrentUser -Force -SkipPublisherCheck

.\scripts\ci\validate-repository.ps1 -Root .
.\scripts\ci\check-comments.ps1 -Root .
Invoke-ScriptAnalyzer -Path .\scripts -Recurse -Severity Error,Warning
Invoke-ScriptAnalyzer -Path .\tests -Recurse -Severity Error,Warning
Invoke-Pester -Path .\tests -CI
```

`-CI` は終了コードを設定するため、Pesterの結果が失敗なら処理は異常終了する。開発用の対話シェルで終了させたくない場合は `-CI` を外す。

## ブランチ保護（手動で設定）

初回Pull RequestのActionsチェックが成功してから、GitHubのリポジトリ `Settings` → `Branches` の保護ルール（または利用できるRulesets）で `main` の `PowerShell quality` チェックを必須にする。

- Pull Request経由の変更を推奨
- Required status checks: `PowerShell quality`（実行されたチェック名に合わせて指定）
- 個人開発では、自分自身の承認を必須にするとマージ不能になる場合があるため、必須承認の要否を確認する
- GitHub Actionsが無効化されている場合はリポジトリのActions設定を確認する

## 完了条件

- PR作成・更新でCIが起動する
- JSONまたはPowerShell構文が不正なら失敗する
- 静的解析またはPesterの失敗はPRに反映される
- CIは開発PCのレジストリ・PowerShell Profile・wingetパッケージを変更しない
