[CmdletBinding()]
param(
    [string[]]$Features,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$featureCatalog = [ordered]@{
    F01 = @{ Name = 'Clipboard history'; Plan = 'Open Windows Settings and enable clipboard history manually.' }
    F02 = @{ Name = 'PowerToys'; Plan = 'Check PowerToys availability and configure Run / FancyZones manually.' }
    F03 = @{ Name = 'PowerShell / Git aliases'; Plan = 'Review planned profile and Git alias changes before a future implementation.' }
    F04 = @{ Name = 'VS Code Settings Sync'; Plan = 'Enable Settings Sync in VS Code manually.' }
    F05 = @{ Name = 'winget packages'; Plan = 'Review a future winget installation plan. No packages will be installed now.' }
}

function Resolve-FeatureSelection {
    param(
        [string[]]$Requested,
        [System.Collections.IDictionary]$Catalog
    )

    $tokens = @(
        foreach ($entry in $Requested) {
            foreach ($token in ($entry -split ',')) {
                $token.Trim().ToUpperInvariant()
            }
        }
    )

    if ($tokens.Count -eq 0 -or @($tokens | Where-Object { $_ -eq '' }).Count -gt 0) {
        throw 'Select at least one valid feature ID.'
    }

    if ($tokens -contains 'ALL') {
        if ($tokens.Count -ne 1) {
            throw 'All cannot be combined with other feature IDs.'
        }
        return @($Catalog.Keys)
    }

    $unknown = @($tokens | Where-Object { -not $Catalog.Contains($_) })
    if ($unknown.Count -gt 0) {
        throw "Unknown feature ID(s): $($unknown -join ', ')"
    }

    return @($Catalog.Keys | Where-Object { $tokens -contains $_ })
}

Write-Host '=== Windows Development Environment Setup ==='
Write-Host 'Controller preview: no Windows settings, files, or packages will be changed.'
Write-Host ''

foreach ($id in $featureCatalog.Keys) {
    Write-Host ("{0}  {1}" -f $id, $featureCatalog[$id].Name)
}
Write-Host ''

if (-not $Features -or $Features.Count -eq 0) {
    if ($DryRun) {
        throw 'Specify -Features when using -DryRun (non-interactive mode).'
    }
    $Features = @(Read-Host 'Select IDs (e.g. F01,F03), All, or Cancel')
}

if ($Features.Count -eq 1 -and $Features[0].Trim() -match '^(?i:cancel)$') {
    Write-Host 'Cancelled. No changes made.'
    return
}

$selected = @(Resolve-FeatureSelection -Requested $Features -Catalog $featureCatalog)

Write-Host '=== Planned operations ==='
foreach ($id in $selected) {
    Write-Host ("[{0}] {1}" -f $id, $featureCatalog[$id].Name)
    Write-Host ("  Plan: {0}" -f $featureCatalog[$id].Plan)
    Write-Host '  State: Not implemented (preview only)'
}
Write-Host ''

if ($DryRun) {
    Write-Host 'DryRun complete. No changes made.'
    return
}

$results = [System.Collections.Generic.List[object]]::new()
foreach ($id in $selected) {
    $decision = (Read-Host "[$id] Acknowledge plan? [Yes/Skip/Cancel]").Trim()
    switch -Regex ($decision) {
        '^(?i:yes|y)$' {
            $results.Add([pscustomobject]@{
                    FeatureId = $id
                    Status = 'ManualRequired'
                    Message = 'Feature application is not implemented; no changes made.'
                })
            break
        }
        '^(?i:cancel|c)$' {
            Write-Host 'Cancelled. Remaining features were not processed.'
            break
        }
        default {
            $results.Add([pscustomobject]@{
                    FeatureId = $id
                    Status = 'Skipped'
                    Message = 'Not acknowledged; no changes made.'
                })
        }
    }

    if ($decision -match '^(?i:cancel|c)$') {
        break
    }
}

Write-Host '=== Results ==='
foreach ($result in $results) {
    Write-Host ("{0}: {1} - {2}" -f $result.FeatureId, $result.Status, $result.Message)
}
Write-Host 'No changes made.'
