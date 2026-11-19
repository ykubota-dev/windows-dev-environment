# Setup controller (Phase 2 - intake preview)

The terminal intake is implemented in `scripts/setup.ps1`. It is a **preview-only** controller: it does not modify Windows settings, install packages, create backups, or write configuration files.

## Usage

From the repository root in PowerShell:

```powershell
.\scripts\setup.ps1
.\scripts\setup.ps1 -Features F01,F03
.\scripts\setup.ps1 -Features All -DryRun
```

The interactive menu accepts one or more IDs separated by commas, `All`, or `Cancel`. Unknown IDs fail without applying anything. `-DryRun` requires explicit `-Features`, so it never blocks awaiting input.

The controller displays the selected features and their planned operations. Without `-DryRun`, it asks for each feature:

- `Yes` / `Y`: acknowledge the preview, returning `ManualRequired` because the feature handler does not exist yet.
- `Skip` / Enter / other input: return `Skipped`. Empty input never authorizes a change.
- `Cancel` / `C`: stop processing further features.

No answer triggers actual changes in this phase. Later implementation PRs must introduce explicit apply handlers, state revalidation, per-feature backup, and post-apply verification before allowing any write.

## Test

```powershell
Invoke-Pester -Path ./tests/setup.Tests.ps1 -CI
```

The repository's Windows GitHub Actions CI runs the Pester tests and PowerShell static analysis. This phase is not an integration test of real Windows settings.

## 表示言語と操作

受付画面・実行予定・結果メッセージは日本語で表示します。CLI引数（`-Features`、`-DryRun`）、機能ID、選択入力（`All`、`Cancel`、`Yes`、`Skip`）は互換性のため英語のまま維持します。`Yes` はプレビュー内容の確認のみを意味し、設定変更は行いません。`Skip` は当該機能を飛ばし、`Cancel` は残りの処理を中止します。
