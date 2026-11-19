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
