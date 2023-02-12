$decimals = Read-Host "Combien de décimales de Pi souhaitez-vous calculer?" #10000000

$CalculatePiDecimals = {
    param($Limit)

    $k = 0
    $pi = 0
    $sign = 1
    Write-Host "Limite : $Limit"
    while ($k -lt $Limit) {
        $pi = $pi + $sign * 4 / (2 * $k + 1)
        $k++
        $sign *= -1
    } 
}

Measure-Command {
    $MaxThreads = 1 # Nombre de threads physiques
    $RunspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads)
    $RunspacePool.Open()
    $Jobs = @()
    
    1..1 | Foreach-Object { # Nombre de threads logiques
        Write-Host "Lancement du thread $_" -ForegroundColor Green
        $PowerShell = [powershell]::Create()
        $PowerShell.RunspacePool = $RunspacePool
        $PowerShell.AddScript($CalculatePiDecimals).AddArgument($decimals + 5)
        $Jobs += $PowerShell.BeginInvoke()
    }
    
    while ($Jobs.IsCompleted -contains $false) {
        Start-Sleep -Milliseconds 100
    }
} | Select-Object TotalSeconds
