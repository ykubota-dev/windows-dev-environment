[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Interactive terminal UI intentionally writes prompts and status messages to the host.')]
[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$GitConfigPath = (Join-Path $HOME '.gitconfig'),
    [string]$ManagedConfigPath = (Join-Path (Join-Path $HOME '.config/windows-dev-environment') 'git-aliases.gitconfig')
)

$ErrorActionPreference = 'Stop'

function Get-FileFingerprint {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return 'MISSING'
    }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Invoke-F02GitAlias {
    param([switch]$DryRun, [string]$GitConfigPath, [string]$ManagedConfigPath)

    $source = Join-Path $PSScriptRoot '../../config/git/aliases.gitconfig'
    $gitCommand = Get-Command git -ErrorAction SilentlyContinue
    if ($null -eq $gitCommand) {
        return [pscustomobject]@{ FeatureId = 'F02'; Status = 'Failed'; Message = 'Gitが見つかりません。' }
    }

    $sourceContent = [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $source).Path)
    $sourceFingerprint = Get-FileFingerprint -Path $source
    $globalFingerprint = Get-FileFingerprint -Path $GitConfigPath
    $managedFingerprint = Get-FileFingerprint -Path $ManagedConfigPath

    $existingIncludes = @()
    if ($globalFingerprint -ne 'MISSING') {
        $existingIncludes = @(& git config --file $GitConfigPath --get-all include.path 2>$null)
        if ($LASTEXITCODE -gt 1) {
            throw '既存のGit設定を読み取れませんでした。'
        }
    }
    $hasInclude = @($existingIncludes | Where-Object { $_ -eq $ManagedConfigPath }).Count -gt 0
    $managedContent = if ($managedFingerprint -ne 'MISSING') {
        [System.IO.File]::ReadAllText($ManagedConfigPath)
    }
    else { '' }

    $needsManagedFile = $managedContent -cne $sourceContent
    if (-not $needsManagedFile -and $hasInclude) {
        return [pscustomobject]@{ FeatureId = 'F02'; Status = 'Skipped'; Message = 'Git Aliasは設定済みです。' }
    }

    $aliasNames = @('st', 'co', 'br', 'lg')
    foreach ($name in $aliasNames) {
        if ($globalFingerprint -eq 'MISSING' -or $hasInclude) { continue }
        $existing = @(& git config --file $GitConfigPath --get-all "alias.$name" 2>$null)
        if ($LASTEXITCODE -gt 1) {
            throw "既存のGit Aliasを確認できません: $name"
        }
        if ($existing.Count -gt 0) {
            throw "既存のGit Aliasと競合しています: $name。既存設定は変更しません。"
        }
    }

    Write-Host '[F02] Git Aliasの変更計画'
    foreach ($alias in @('st = status', 'co = checkout', 'br = branch', 'lg = log --oneline --graph --decorate -10')) {
        Write-Host "  + $alias"
    }
    Write-Host "  管理ファイル: $ManagedConfigPath"
    Write-Host "  Git設定: $GitConfigPath"
    Write-Host "  操作: 管理ファイルの作成・更新とinclude.pathの追加（必要な場合のみ）"

    if ($DryRun) {
        return [pscustomobject]@{ FeatureId = 'F02'; Status = 'Skipped'; Message = 'DryRun: 変更計画を表示しました。' }
    }

    $answer = (Read-Host '[F02] 上記の変更を承認しますか？ [Yes / Skip / Cancel]').Trim()
    if ($answer -notmatch '^(?i:yes|y)$') {
        return [pscustomobject]@{ FeatureId = 'F02'; Status = 'Skipped'; Message = '変更は承認されませんでした。' }
    }

    if ((Get-FileFingerprint -Path $source) -ne $sourceFingerprint -or
        (Get-FileFingerprint -Path $GitConfigPath) -ne $globalFingerprint -or
        (Get-FileFingerprint -Path $ManagedConfigPath) -ne $managedFingerprint) {
        throw '承認後にファイルが変更されました。再度実行して差分を確認してください。'
    }

    $backupPaths = [System.Collections.Generic.List[string]]::new()
    $stamp = [DateTime]::UtcNow.ToString('yyyyMMddHHmmssfffffff')
    foreach ($path in @($GitConfigPath, $ManagedConfigPath)) {
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            $backupPath = "$path.$stamp.bak"
            Copy-Item -LiteralPath $path -Destination $backupPath -ErrorAction Stop
            $backupPaths.Add($backupPath)
        }
    }

    if ($needsManagedFile) {
        $parent = Split-Path -Parent $ManagedConfigPath
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
            $null = New-Item -ItemType Directory -Path $parent -Force
        }
        [System.IO.File]::WriteAllText($ManagedConfigPath, $sourceContent, [System.Text.UTF8Encoding]::new($false))
    }
    if (-not $hasInclude) {
        & git config --file $GitConfigPath --add include.path $ManagedConfigPath
        if ($LASTEXITCODE -ne 0) {
            throw 'include.pathの登録に失敗しました。'
        }
    }

    $currentIncludes = @(& git config --file $GitConfigPath --get-all include.path 2>$null)
    if ($currentIncludes -notcontains $ManagedConfigPath -or
        (Get-FileFingerprint -Path $ManagedConfigPath) -eq 'MISSING' -or
        [System.IO.File]::ReadAllText($ManagedConfigPath) -cne $sourceContent) {
        throw '適用後の検証に失敗しました。'
    }

    $backupMessage = if ($backupPaths.Count -gt 0) { " バックアップ: $($backupPaths -join ', ')" } else { '' }
    return [pscustomobject]@{ FeatureId = 'F02'; Status = 'Success'; Message = "Git Aliasを設定しました。$backupMessage" }
}

if ($MyInvocation.InvocationName -ne '.') {
    try {
        Invoke-F02GitAlias -DryRun:$DryRun -GitConfigPath $GitConfigPath -ManagedConfigPath $ManagedConfigPath
    }
    catch {
        [pscustomobject]@{ FeatureId = 'F02'; Status = 'Failed'; Message = $_.Exception.Message }
    }
}
