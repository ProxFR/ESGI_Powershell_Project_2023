#$decimals = Read-Host "Combien de décimales de Pi souhaitez-vous calculer ?"

function StressTool {
    param (
        [int]$decimals,
        [int]$thread
    )
    write-host $decimals
    write-host $thread
    $CalculatePiDecimals = {
        param($Limit)
    
        $k = 0
        $pi = 0
        $sign = 1
        while ($k -lt $Limit) {
            $pi = $pi + $sign * 4 / (2 * $k + 1)
            $k++
            $sign *= -1
        } 
    }
    
    $MaxThreads = $thread # Nombre de threads physiques
    $RunspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads)
    $RunspacePool.Open()
    $Jobs = @()
    
    1..$thread | Foreach-Object { # Nombre de threads logiques
        Write-Host "Lancement du thread $_" -ForegroundColor Green
        $PowerShell = [powershell]::Create()
        $PowerShell.RunspacePool = $RunspacePool
        $PowerShell.AddScript($CalculatePiDecimals).AddArgument($decimals + 5)
        $Jobs += $PowerShell.BeginInvoke()
    }
    
    while ($Jobs.IsCompleted -contains $false) {
        Start-Sleep -Milliseconds 100
    }
}


start powershell {StressTool -decimals 10000000 -thread 100; Read-Host}