$continue = $true
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

while ($continue){
    write-host "`n----------------- Deploy a VM on Azure -----------------" -ForegroundColor Cyan
    write-host “1. mon action 1” -ForegroundColor Cyan
    write-host "2. mon action 2" -ForegroundColor Cyan

    write-host "`n------------ Benchmark/Stress the instance -------------" -ForegroundColor Green
    write-host “3. Show the comparison results” -ForegroundColor Green
    write-host "4. Start the benchmark (single thread)" -ForegroundColor Green
    write-host "5. Start a stress test (all cores)" -ForegroundColor Green
    write-host "6. Start an advanced stress test" -ForegroundColor Green

    write-host "`nx. exit`n" -ForegroundColor Magenta

    $choix = read-host “faire un choix ”
    switch ($choix){
        1{commande de mon action 1}
        2{commande de mon action 2}
        ‘x’ {$continue = $false}
        default {Write-Host "Choix invalide"-ForegroundColor Red}
    }
}