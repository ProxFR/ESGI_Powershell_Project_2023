$Scriptblock = { # Utilisation de la formule de Leibniz
    $k = 0
    $pi = 0
    $limit = 10000000 + 5
    $sign = 1
    Write-Host $limit
    while ($k -lt $limit) {
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
        $PowerShell.AddScript($ScriptBlock).AddArgument($_)
        $Jobs += $PowerShell.BeginInvoke()
    }
    
    while ($Jobs.IsCompleted -contains $false) {
        Start-Sleep -Milliseconds 100
    }
} | Select-Object TotalSeconds
