# コーディングポリシー

## 基本原則

AIエージェントが実装・保守するPowerShellコードでは、コメントを原則禁止する。意図は関数名、変数名、型、処理構造、テストで表現する。コードで表現できない契約は設計文書に記載する。

## 対象

`scripts/` と `tests/` 以下の `.ps1`、`.psm1`、`.psd1` を検証する。`docs/`、YAML、JSON、GitHub Actionsの設定は初版の対象外。

## 例外

安全上の根拠をコードの近くに置かなければならない場合に限り、先頭を `# SAFETY: <具体的な根拠>` とする。空の理由は認めない。行コメントとブロックコメントの先頭マーカーに同じ原則を適用する。

PSScriptAnalyzerの抑制は説明コメントではなく、`SuppressMessageAttribute` の `Justification` に理由を設定する。一般的な TODO、NOTE、手順説明、コメント化したコードは許可しない。

## CI

`scripts/ci/check-comments.ps1` はPowerShellのParserが返すコメントトークンを検査し、違反ファイル・行番号を表示して非ゼロ終了とする。文字列内の `#` は検出しない。

```powershell
./scripts/ci/check-comments.ps1 -Root .
```

GitHub Actionsの `PowerShell quality` ジョブで構文検証の後に実行する。コメント禁止チェックはPSScriptAnalyzer本体を改修せず、独立したポリシー検証として運用する。
