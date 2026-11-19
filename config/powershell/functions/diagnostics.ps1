function ports {
    param([Parameter(Mandatory, Position = 0)][ValidateRange(1, 65535)][int]$Port)
    $connections = @(Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue)
    foreach ($connection in $connections) {
        $process = Get-Process -Id $connection.OwningProcess -ErrorAction SilentlyContinue
        [pscustomobject]@{
            Port = $connection.LocalPort
            LocalAddress = $connection.LocalAddress
            State = $connection.State
            PID = $connection.OwningProcess
            ProcessName = if ($process) { $process.ProcessName } else { 'Unknown' }
        }
    }
}

function which {
    param([Parameter(Mandatory, Position = 0)][string]$Name)
    Get-Command -Name $Name -All -ErrorAction SilentlyContinue |
        Select-Object Name, CommandType, Source, Definition
}

function reload-profile {
    $managedProfile = Join-Path (Join-Path (Join-Path $HOME '.config') 'windows-dev-environment') 'powershell/profile.ps1'
    if (-not (Test-Path -LiteralPath $managedProfile -PathType Leaf)) {
        throw "管理Profileが見つかりません: $managedProfile"
    }
    . $managedProfile
}
