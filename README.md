# Windows Development Environment

Windows 11の開発環境を、**機能ごとに選択して安全にセットアップ・再現する**ための公開リポジトリです。

> **現在の状態：F01（クリップボード履歴）の状態確認・操作案内に対応**
>
> 未実装の機能はIDを予約せず、実装時に採番・登録します。

## 目的

- 新しいWindows 11 PCで開発環境を再現しやすくする
- 日常的な操作・開発作業を効率化する
- 設定と変更理由をGitで追跡可能にする
- 既存環境を保護し、適用前に差分を確認できるようにする

## 対応機能

| ID | 機能 | 状態 |
| --- | --- | --- |
| F01 | Windowsクリップボード履歴（Win + V） | 実装済み（状態確認・手動設定案内） |

今後の実装候補（未採番）：Git Alias、PowerShell Profile、PowerToys Run / FancyZones、VS Code Settings Sync、wingetパッケージ管理、AutoHotkey、Everything。

機能IDは実装時に連番で割り当て、既存IDは原則変更しません。Git AliasとPowerShell Profileは独立した機能として実装します。

Microsoft IMEの辞書は独立した `engineer-ime-dictionary` リポジトリで管理し、ここでは重複して収録しません。

## 設計方針

1. **機能選択方式：** 実行する機能だけを選択できるようにする。
2. **変更前の確認：** 変更内容と既存設定との差分を提示し、明示的に承認された変更だけを実施する。Enterだけでは承認しない。
3. **バックアップ：** 既存設定を変更する場合、承認後・変更前にバックアップする。バックアップに失敗したら変更しない。
4. **冪等性：** 再実行時に重複追記・重複インストールを避ける。
5. **制約尊重：** 組織のポリシーや権限を回避せず、認証情報や端末固有の秘密をGitに含めない。

## CI（継続的インテグレーション）

`.github/workflows/ci.yml` で、`main` 向けPRおよび `main` / `develop/**` へのpush時にWindowsランナー上の検証を実施します。

| チェック | 内容 |
| --- | --- |
| PowerShell構文 | `.ps1`, `.psm1`, `.psd1` のパースエラー |
| JSON構文 | `.json` ファイルの解析エラー |
| コメント禁止Lint | 通常コメントは禁止。安全上の理由を記述する `SAFETY:` のみ許容 |
| PSScriptAnalyzer | `scripts/`、`tests/` のError/Warning |
| Pester | `tests/` 配下の単体テスト |

CIはPC設定の変更やアプリの導入を行いません。利用方法と保護設定については [CIガイド](docs/ci-guide.md) を参照してください。

## 導入・利用方法

現在はF01の状態確認とGUI操作案内が利用できます。

```powershell
.\scripts\setup.ps1 -Features F01 -DryRun
.\scripts\setup.ps1 -Features F01
```

`-Features` を指定しても機能ごとの確認は省略しません。将来の機能は実装時にカタログへ追加します。

## ドキュメント

- [基本設計](docs/basic-design.md) — 目的・機能範囲・アーキテクチャ・非機能要件
- [詳細設計](docs/detailed-design.md) — モジュール・CLI・差分承認・エラー・テスト仕様
- [セットアップガイド](docs/setup-guide.md) — Windowsでの取得・事前確認・将来の利用手順
- [CIガイド](docs/ci-guide.md) — CIの構成、ローカル検証、ブランチ保護

## 開発フロー

`main` を安定版とし、`develop/<feature-name>` からPRで変更します。実装時に機能IDを採番し、`scripts/setup.ps1` の機能カタログへ追加します。

## ライセンス

[MIT License](LICENSE)
