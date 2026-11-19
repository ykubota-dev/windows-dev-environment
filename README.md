# Windows Development Environment

Windows 11の開発環境を、**機能ごとに選択して安全にセットアップ・再現する**ための公開リポジトリです。

> **現在の状態：設計完了・CI基盤構築中**
>
> このブランチにはCIワークフローと検証スクリプトを含みます。**Windows環境を変更するセットアップスクリプトは未実装です。** CIが実際に成功したかどうかはPull RequestのActions結果を確認してください。

## 目的

- 新しいWindows 11 PCで開発環境を再現しやすくする
- 日常的な操作・開発作業を効率化する
- 設定と変更理由をGitで追跡可能にする
- 既存環境を保護し、適用前に差分を確認できるようにする

## 対応機能（計画）

| ID | 機能 | 初版の方式 |
| --- | --- | --- |
| F01 | Windowsクリップボード履歴（Win + V） | 状態確認・手動設定案内 |
| F02 | PowerToys Run / FancyZones | wingetで導入、GUI設定案内 |
| F03 | PowerShell Profile / Git Alias | 差分承認後に設定を適用 |
| F04 | VS Code Settings Sync | VS Code確認・手動同期案内 |
| F05 | wingetパッケージ管理 | インストール予定を確認して導入 |
| F06 | AutoHotkey | 将来対応 |
| F07 | Everything | 将来対応 |

Microsoft IMEの辞書は独立した `engineer-ime-dictionary` リポジトリで管理し、ここでは重複して収録しません。

## 設計方針

1. **機能選択方式：** 実行する機能だけを選択できるようにする。
2. **変更前の確認：** 変更内容と既存設定との差分を提示し、明示的に承認された変更だけを実施する。Enterだけでは承認しない。
3. **バックアップ：** 既存設定を変更する場合、承認後・変更前にバックアップする。バックアップに失敗したら変更しない。
4. **冪等性：** 再実行時に重複追記・重複インストールを避ける。
5. **制約尊重：** 組織のポリシーや権限を回避せず、認証情報や端末固有の秘密をGitに含めない。

## CI（継続的インテグレーション）

`.github/workflows/ci.yml` で、`main` 向けPRおよび `main` へのpush時にWindowsランナー上の検証を実施します。

| チェック | 内容 |
| --- | --- |
| PowerShell構文 | `.ps1`, `.psm1`, `.psd1` のパースエラー |
| JSON構文 | `.json` ファイルの解析エラー |
| PSScriptAnalyzer | `scripts/`、`tests/` のError/Warning |
| Pester | `tests/` 配下の単体テスト |

CIはPC設定の変更やアプリの導入を行いません。利用方法と保護設定については [CIガイド](docs/ci-guide.md) を参照してください。

## 導入・利用方法

現段階ではドキュメントの確認とCI検証のみ可能です。詳細は [セットアップガイド](docs/setup-guide.md) を参照してください。

実装後に提供する予定のコマンド（**現時点では実行不可**）：

```powershell
# リポジトリのルートから
.\scripts\setup.ps1
.\scripts\setup.ps1 -Features F03,F05
.\scripts\setup.ps1 -Features F03 -DryRun
.\scripts\verify.ps1
```

実装後も、`-Features` 指定だけで確認を省略することはありません。

## ドキュメント

- [基本設計](docs/basic-design.md) — 目的・機能範囲・アーキテクチャ・非機能要件
- [詳細設計](docs/detailed-design.md) — モジュール・CLI・差分承認・エラー・テスト仕様
- [セットアップガイド](docs/setup-guide.md) — Windowsでの取得・事前確認・将来の利用手順
- [CIガイド](docs/ci-guide.md) — CIの構成、ローカル検証、ブランチ保護

## 開発フロー

`main` を安定版とし、`develop/<feature-name>` の短命ブランチからPull Requestで変更します。常設の`develop` ブランチは置きません。初期基盤は `develop/project-foundation`、CIは `develop/ci-pipeline`、次のセットアップ基盤は `develop/setup-controller` で実装します。

## ライセンス

[MIT License](LICENSE)
