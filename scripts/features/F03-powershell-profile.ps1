[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Interactive installation displays its plan and approval prompt.')]
[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$ProfilePath = $PROFILE.CurrentUserCurrentHost,
    [string]$ManagedDirectory = (Join-Path (Join-Path $HOME '.config/windows-dev-environment') 'powershell')
)

$ErrorActionPreference = 'Stop'

function Get-F03Fingerprint {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return 'MISSING' }
    (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Invoke-F03PowerShellProfile {
    param([switch]$DryRun, [string]$ProfilePath, [string]$ManagedDirectory)

    if ($PSVersionTable.PSVersion.Major -ne 7) {
        return [pscustomobject]@{ FeatureId = 'F03'; Status = 'Failed'; Message = 'PowerShell 7のみ対応しています。' }
    }

    $sourceDirectory = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../config/powershell')).Path
    $relativeFiles = @('profile.ps1', 'functions/navigation.ps1', 'functions/filesystem.ps1', 'functions/diagnostics.ps1', 'functions/git.ps1')
    $startMarker = '# BEGIN windows-dev-environment F03'
    $endMarker = '# END windows-dev-environment F03'
    $managedEntry = Join-Path $ManagedDirectory 'profile.ps1'
    $block = "$startMarker`n. '$($managedEntry.Replace("'", "''"))'`n$endMarker"
    $profileExists = Test-Path -LiteralPath $ProfilePath -PathType Leaf
    $profileContent = if ($profileExists) { [System.IO.File]::ReadAllText($ProfilePath) } else { '' }
    $startCount = ([regex]::Matches($profileContent, [regex]::Escape($startMarker))).Count
    $endCount = ([regex]::Matches($profileContent, [regex]::Escape($endMarker))).Count
    if ($startCount -gt 1 -or $endCount -gt 1 -or $startCount -ne $endCount) {
        throw 'Profile管理ブロックが不正です。自動変更しません。'
    }
    $newProfile = if ($startCount -eq 0) {
        if ($profileContent.Length -eq 0) { "$block`n" }
        else { "$($profileContent.TrimEnd("`r", "`n"))`n`n$block`n" }
    }
    else {
        $pattern = '(?s)' + [regex]::Escape($startMarker) + '.*?' + [regex]::Escape($endMarker)
        $match = [regex]::Match($profileContent, $pattern)
        $profileContent.Substring(0, $match.Index) + $block + $profileContent.Substring($match.Index + $match.Length)
    }

    $changes = [System.Collections.Generic.List[object]]::new()
    $snapshots = @{}
    $snapshots[$ProfilePath] = Get-F03Fingerprint $ProfilePath
    if ($newProfile -cne $profileContent) {
        $changes.Add([pscustomobject]@{ Source = $null; Destination = $ProfilePath; Content = $newProfile })
    }
    foreach ($relative in $relativeFiles) {
        $source = Join-Path $sourceDirectory $relative
        $destination = Join-Path $ManagedDirectory $relative
        $sourceContent = [System.IO.File]::ReadAllText($source)
        $snapshots[$source] = Get-F03Fingerprint $source
        $snapshots[$destination] = Get-F03Fingerprint $destination
        $oldContent = if (Test-Path -LiteralPath $destination -PathType Leaf) { [System.IO.File]::ReadAllText($destination) } else { $null }
        if ($sourceContent -cne $oldContent) {
            $changes.Add([pscustomobject]@{ Source = $source; Destination = $destination; Content = $sourceContent })
        }
    }
    if ($changes.Count -eq 0) {
        return [pscustomobject]@{ FeatureId = 'F03'; Status = 'Skipped'; Message = 'PowerShell Profileは設定済みです。' }
    }

    Write-Host '[F03] PowerShell 7 Profileの変更計画'
    foreach ($change in $changes) { Write-Host ("  更新: {0}" -f $change.Destination) }
    Write-Host "  Profile管理ブロック: $startMarker ～ $endMarker"
    if ($DryRun) {
        return [pscustomobject]@{ FeatureId = 'F03'; Status = 'Skipped'; Message = 'DryRun: 変更計画を表示しました。' }
    }
    $answer = (Read-Host '[F03] 変更を承認しますか？ [Yes / Skip / Cancel]').Trim()
    if ($answer -notmatch '^(?i:yes|y)$') {
        return [pscustomobject]@{ FeatureId = 'F03'; Status = 'Skipped'; Message = '変更は承認されませんでした。' }
    }

    foreach ($path in @($snapshots.Keys)) {
        if ((Get-F03Fingerprint $path) -ne $snapshots[$path]) {
            throw "承認後にファイルが変更されました: $path"
        }
    }
    $backups = [System.Collections.Generic.List[string]]::new()
    $stamp = [DateTime]::UtcNow.ToString('yyyyMMddHHmmssfffffff')
    foreach ($change in $changes) {
        if (Test-Path -LiteralPath $change.Destination -PathType Leaf) {
            $backup = "$($change.Destination).$stamp.bak"
            Copy-Item -LiteralPath $change.Destination -Destination $backup -ErrorAction Stop
            $backups.Add($backup)
        }
    }
    foreach ($change in $changes) {
        $parent = Split-Path -Parent $change.Destination
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
            $null = New-Item -ItemType Directory -Path $parent -Force -ErrorAction Stop
        }
        [System.IO.File]::WriteAllText($change.Destination, $change.Content, [System.Text.UTF8Encoding]::new($false))
    }
    foreach ($change in $changes) {
        if ([System.IO.File]::ReadAllText($change.Destination) -cne $change.Content) {
            throw "適用後の検証に失敗しました: $($change.Destination)"
        }
    }
    [pscustomobject]@{
        FeatureId = 'F03'
        Status = 'Success'
        Message = "PowerShell 7 Profileを設定しました。バックアップ: $($backups -join ', ')"
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    try {
        Invoke-F03PowerShellProfile -DryRun:$DryRun -ProfilePath $ProfilePath -ManagedDirectory $ManagedDirectory
    }
    catch {
        [pscustomobject]@{ FeatureId = 'F03'; Status = 'Failed'; Message = $_.Exception.Message }
    }
}
