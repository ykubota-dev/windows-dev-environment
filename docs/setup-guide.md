# セットアップガイド

## 1. 現在の提供状況

このリポジトリは **Phase 1：設計・初期構成** の段階です。セットアップスクリプトはまだありません。以下はリポジトリを入手して設計を確認するための手順と、実装後に利用する想定の操作です。

## 2. 事前条件

- Windows 11
- Git、またはGitHubからZIPを取得できるブラウザ
- 実装後の自動化ではPowerShell 7を推奨（正式な最低バージョンは実装時に確定）
- パッケージ導入を行う場合はwingetを利用できること
- 会社管理端末では管理者の許可と端末ポリシーを優先すること

## 3. ソースコードの取得

### Gitが使える場合

PowerShellを開き、作業ディレクトリへ移動して実行：

```powershell
cd $HOME
git clone --branch develop/project-foundation https://github.com/ykubota-dev/windows-dev-environment.git
cd windows-dev-environment
Get-ChildItem
```

### Gitが使えない場合

1. [GitHubの対象ブランチ](https://github.com/ykubota-dev/windows-dev-environment/tree/develop/project-foundation) を開く。
2. `Code` → `Download ZIP` を選択する。
3. ZIPを任意の作業フォルダーに展開する。
4. エクスプローラーで `README.md` があるフォルダーを開き、アドレスバーに `powershell` と入力してEnterを押す。起動したPowerShellの作業ディレクトリはそのフォルダーになる。
5. `Get-Location` および `Get-ChildItem` で配置を確認する。

## 4. 現在できること

```powershell
Get-Content .\README.md
Get-Content .\docs\basic-design.md
Get-Content .\docs\detailed-design.md
```

**注意：** `scripts/setup.ps1`、`scripts/verify.ps1` は未実装です。現時点で実行しないでください。空ディレクトリはGitに保存されないため、将来の配置先には `.gitkeep` を置いています。

## 5. 実装後の利用予定（コマンド例、現在は実行不可）

```powershell
# リポジトリルート（README.mdがある場所）から
.\scripts\setup.ps1

# F03とF05を選択
.\scripts\setup.ps1 -Features F03,F05

# 変更計画と差分の確認のみ
.\scripts\setup.ps1 -Features F03 -DryRun

# 状態確認
.\scripts\verify.ps1
```

通常実行では機能を選択し、差分と操作予定を確認した後、変更ごとに明示的に承認します。Enterキーのみでは承認されません。既存設定を変更するときは、**承認 → バックアップ → 適用 → 検証** の順とします。DryRunではバックアップを含む一切の書き込みを行いません。

## 6. セキュリティ・注意事項

- このリポジトリはPublicです。トークン、認証情報、端末・利用者に固有の秘密をコミットしないでください。
- 端末のセキュリティ設定、実行ポリシー、組織の制限を回避しないでください。
- 将来のスクリプトでも既存環境の一括上書きや暗黙のインストールを行わない方針です。
- スクリプトの完成と動作検証後に初めてセットアップ操作を案内します。
