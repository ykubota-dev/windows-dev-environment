# 基本設計書

- 文書ID：BASIC-001
- 対象：windows-dev-environment
- バージョン：0.2
- 状態：初版確定（Phase 1）
- 対象OS：Windows 11

## 1. 背景と目的

日常的に使用するWindows開発環境の設定をGitで管理し、新しい端末でも必要な機能を選択して安全に再現できるようにする。手作業による設定漏れを削減し、変更履歴と導入手順を公開可能な形で整理する。

## 2. 対象範囲

| ID | 機能 | 初版対応 | 適用方式 |
| --- | --- | --- | --- |
| F01 | クリップボード履歴 | 対応 | 状態確認とGUI操作案内 |
| F02 | PowerToys Run / FancyZones | 対応 | 導入とGUI設定案内 |
| F03 | PowerShell Profile / Git Alias | 対応 | ファイル差分承認後の適用 |
| F04 | VS Code Settings Sync | 対応 | インストール確認と認証・同期案内 |
| F05 | wingetアプリ管理 | 対応 | インストール予定承認後の適用 |
| F06 | AutoHotkey | 将来 | 対象外 |
| F07 | Everything | 将来 | 対象外 |

Microsoft IME辞書は別リポジトリで管理する。Windows以外のOS、秘密情報の同期、既存アプリの強制更新・削除は対象外。

## 3. 構成

```text
GitHub / windows-dev-environment (Public)
    └─ scripts/setup.ps1 [Phase 2で実装]
         ├─ 事前チェック・機能選択
         ├─ 変更計画・差分表示・承認
         ├─ バックアップ・機能適用
         └─ 結果集約・検証
              ├─ F01 Windows
              ├─ F02 PowerToys
              ├─ F03 PowerShell / Git
              ├─ F04 VS Code
              └─ F05 winget
```

制御処理と機能固有の処理を分離する。機能ごとに独立した適用・検証処理を持つ。GUI操作が必要なものは手動作業として明示する。

## 4. 運用方式

- デフォルトは対話型の機能選択方式。
- `-Features` による非対話的な対象指定を可能にするが、変更の承認は省略しない。
- ファイル差分、パッケージの導入予定、手動操作の内容を変更前に示す。
- 変更前にバックアップする。明示的承認なしでは変更しない。
- 再実行時に設定を重複させない。
- 実行結果は `Success`、`Skipped`、`Failed`、`ManualRequired` として集約する。

## 5. 非機能要件

| 観点 | 要件 |
| --- | --- |
| 安全性 | 差分表示・明示承認・既存ファイルのバックアップ |
| 冪等性 | 再実行による重複設定・重複導入を防ぐ |
| 可観測性 | 対象・結果・失敗理由・手動対応事項を表示する |
| 保守性 | 機能別モジュールと設定を独立させる |
| 実行環境 | Windows 11、PowerShell 7推奨。事前検査で互換性判定する |
| セキュリティ | トークン・認証情報・端末固有情報をコミットしない |
| 権限 | 昇格が必要なら事前に明示し、組織ポリシーを回避しない |
| 障害時 | 失敗項目を記録し、独立機能の継続可否を判定する |

## 6. 開発フェーズ

1. **Phase 1 / 基盤：** README、LICENSE確認、設計書、導入ガイド、初期ディレクトリ。
2. **Phase 2 / セットアップ制御・CLI：** 機能選択、差分確認、バックアップ、PowerShell/Git、winget。
3. **Phase 3 / GUI：** クリップボード履歴、PowerToys、VS Code。
4. **Phase 4 / 拡張：** AutoHotkey、Everything。

## 7. Git運用

`main` は安定版。 `develop/project-foundation` からのPRを経て、以後は最新`main`から `develop/setup-controller`、`develop/powershell-git`、`develop/winget-installer`、`develop/powertoys`、`develop/windows-clipboard`、`develop/vscode-settings` 等の作業ブランチを作る。マージはリポジトリ所有者が行う。
