# セットアップガイド

## 1. 現在の提供状況

F01（クリップボード履歴）の状態確認とGUI操作案内を提供しています。その他の機能は未実装で、機能IDを予約していません。

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
git clone --branch main https://github.com/ykubota-dev/windows-dev-environment.git
cd windows-dev-environment
Get-ChildItem
```

### Gitが使えない場合

1. [GitHubの対象ブランチ](https://github.com/ykubota-dev/windows-dev-environment/tree/main) を開く。
2. `Code` → `Download ZIP` を選択する。
3. ZIPを任意の作業フォルダーに展開する。
4. エクスプローラーで `README.md` があるフォルダーを開き、アドレスバーに `powershell` と入力してEnterを押す。起動したPowerShellの作業ディレクトリはそのフォルダーになる。
5. `Get-Location` および `Get-ChildItem` で配置を確認する。

## 4. 現在できること

```powershell
.\scripts\setup.ps1 -Features F01 -DryRun
.\scripts\setup.ps1 -Features F01
.\scripts\setup.ps1 -Features All -DryRun
```

現在、AllはF01だけを対象とします。未実装機能のIDは指定できません。通常実行では機能ごとに明示的な承認が必要で、Enterだけでは承認されません。DryRunでは書き込みを行いません。

## 6. セキュリティ・注意事項

- このリポジトリはPublicです。トークン、認証情報、端末・利用者に固有の秘密をコミットしないでください。
- 端末のセキュリティ設定、実行ポリシー、組織の制限を回避しないでください。
- 将来のスクリプトでも既存環境の一括上書きや暗黙のインストールを行わない方針です。
- スクリプトの完成と動作検証後に初めてセットアップ操作を案内します。
