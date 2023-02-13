##################################################################################################################
################################################ BENCHMARKINGTOOL ################################################
##################################################################################################################

function BenchmarkingTool {
    param (
        [int]$decimals,
        [int]$thread
    )
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
    
    $result = Measure-Command {
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
    } | Select-Object TotalSeconds
    Write-Host "Résultat : $($result.TotalSeconds) secondes" -ForegroundColor Yellow
}

##################################################################################################################
##################################################### MENU #######################################################
##################################################################################################################


$continue = $true

while ($continue){
    Clear-Host # Clear the console

    write-host @"
    _____           _      _     _____                       _____ _          _ _   ______  _____  _____ _____ 
   |  __ \         (_)    | |   |  __ \                     / ____| |        | | | |  ____|/ ____|/ ____|_   _|
   | |__) | __ ___  _  ___| |_  | |__) |____      _____ _ _| (___ | |__   ___| | | | |__  | (___ | |  __  | |  
   |  ___/ '__/ _ \| |/ _ \ __| |  ___/ _ \ \ /\ / / _ \ '__\___ \| '_ \ / _ \ | | |  __|  \___ \| | |_ | | |  
   | |   | | | (_) | |  __/ |_  | |  | (_) \ V  V /  __/ |  ____) | | | |  __/ | | | |____ ____) | |__| |_| |_ 
   |_|   |_|  \___/| |\___|\__| |_|   \___/ \_/\_/ \___|_| |_____/|_| |_|\___|_|_| |______|_____/ \_____|_____|
                  _/ |                                                                                         
                 |__/                                                                                          
"@ -ForegroundColor Blue

    write-host "`n----------------- Deploy a VM on Azure -----------------" -ForegroundColor Cyan
    write-host "1. mon action 1" -ForegroundColor Cyan
    write-host "2. mon action 2" -ForegroundColor Cyan

    write-host "`n------------ Benchmark/Stress the instance -------------" -ForegroundColor Green
    write-host "3. Show the comparison results" -ForegroundColor Green
    write-host "4. Start the benchmark (single thread)" -ForegroundColor Green
    write-host "5. Start a stress test (all cores) /!\ Not working /!\" -ForegroundColor Green
    write-host "6. Start an advanced stress test" -ForegroundColor Green

    write-host "`nx. exit`n" -ForegroundColor Magenta

    $choix = read-host “faire un choix ”
    switch ($choix){
        1 {commande de mon action 1}
        2 {commande de mon action 2}
        3 {write-host "Choix 3" -ForegroundColor Red}
        4 {
            Write-Host "Starting benchmarking tool" -foregroundColor DarkYellow
            BenchmarkingTool -decimals 10000000 -thread 1
            Read-Host -Prompt "Press any key to continue..."
        }
        5 {
            Write-Host "Starting stress test" -foregroundColor DarkYellow
            BenchmarkingTool -decimals 100000000 -thread 1
            Read-Host -Prompt "Press any key to continue..."
        }
        ‘x’ {$continue = $false}
        default {Write-Host "Choix invalide" -ForegroundColor Red}
    }
}