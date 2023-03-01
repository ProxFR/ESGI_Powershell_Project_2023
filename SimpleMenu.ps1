Write-Output "Connexion à l'environnement Azure:"
$auth = Connect-AzAccount #On laisse l'authentification à chaque lancement du script pour plus de sécurité et pour laisser l'utilisateur choisir sont tenant si il doit déployer plusieurs VM sur différents tenant

####################################################################################################################
################################################ DEPLOYEMENT SCRIPT ################################################
####################################################################################################################


#################################################### VM CREATION ###################################################
function creationVM {
    New-AzResourceGroupDeployment -ResourceGroupName "VM-Projet-Powershell" -TemplateUri ./templates/azuredeploy.json -DeploymentDebugLogLevel All -Verbose
}

#################################################### VM LISTING ####################################################
function ListVM {
    $VMs = Get-AzVM -ResourceGroupName "VM-Projet-Powershell" -Status
    #$global:VMObject = @()

    $table = foreach ($VM in $VMs) {

        $networkProfile = $VM.NetworkProfile.NetworkInterfaces.id.Split("/") | Select-Object -Last 1
        $PrivateIPAddress = (Get-AzNetworkInterface -Name $networkProfile).IpConfigurations.PrivateIpAddress
        $publicIP = (Get-AzNetworkInterface -Name $networkProfile).IpConfigurations.PublicIpAddress.Id.Split("/") | Select-Object -Last 1
        $publicIPAddress = (Get-AzPublicIpAddress -Name $publicIP).IpAddress

        New-Object psobject -Property @{
            "Nom"              = $VM.Name
            "OS"               = $VM.OsName
            "PowerState"       = $VM.PowerState
            "PrivateIpAddress" = $PrivateIPAddress
            "PublicIpAddress"  = $publicIPAddress
        }
    }
    return $table
}

#################################################### DELETE VM #####################################################

function SupprimerVM {
    Write-Output "Voici la liste des machines virtuels: "
    $VMs = ListVM 
    $VMs | Format-Table -autosize -Property Nom, PowerState, OS, PrivateIpAddress, PublicIpAddress
    $VMDel = read-host "Entrez le nom de la VM à supprimer: "
    foreach ($vm in $VMs) {
        if ($vm.Nom -eq $VMDel) {
            $NomOK = "True"
            $vm = Get-AzVm -Name $VMDel -ResourceGroupName "VM-Projet-Powershell"
            $res = Remove-AzVM -ResourceGroupName "VM-Projet-Powershell" -Name $VMDel -Force -Verbose
            foreach ($nicUri in $vm.NetworkProfile.NetworkInterfaces.Id) {
                $nic = Get-AzNetworkInterface -ResourceGroupName $vm.ResourceGroupName -Name $nicUri.Split('/')[-1]
                Remove-AzNetworkInterface -Name $nic.Name -ResourceGroupName $vm.ResourceGroupName -Force -verbose
            
                foreach ($ipConfig in $nic.IpConfigurations) {
                    if ($ipConfig.PublicIpAddress -ne $null) {
                        Remove-AzPublicIpAddress -ResourceGroupName $vm.ResourceGroupName -Name $ipConfig.PublicIpAddress.Id.Split('/')[-1] -Force -verbose
                    }
                }
            }
            $pattern = $($VMDel) + '_.*(D|d)isk.*([0-9]|[a-z]){32}'
            $DiskName = get-AzDisk -ResourceGroupName "VM-Projet-Powershell" | where-object {$_.name -match $pattern }

            Remove-AzDisk -ResourceGroupName "VM-Projet-Powershell" -DiskName $DiskName.Name -Force -Verbose

            if ($res.Status -eq "Succeeded") {
                Write-Output "La VM $($VMDel) à été correctement supprimé"
            }
            else {
                Write-Output "Il y a eu une erreur dans la suppression de la VM"
            }
        }
    }
    if ($NomOK -ne "True") {
        Write-Output "Le nom entré n'est pas correcte"
    }
    Read-Host -Prompt "Press any key to continue..."
}

#################################################### VM MANAGEMENT #################################################
function GestionVM {
    Write-Output "Voici la liste des machines virtuels: "
    $VMs = ListVM 
    $VMs | Format-Table -autosize -Property Nom, PowerState, OS, PrivateIpAddress, PublicIpAddress
    $VMMod = read-host "Entrez le nom de la VM à gérer: "
    foreach ($vm in $VMs) {
        if ($vm.Nom -eq $VMMod) {
            $NomOK = "True"
            $rep = read-host "
            Que voulez-vous faire?
            1. Démarrer la VM
            2. Éteindre la VM
            "
            switch ($rep) {
                { $_ -eq 1 } { $res = Start-AzVM -ResourceGroupName "VM-Projet-Powershell" -Name $VMMod; $mod = "Démarrée" }
                { $_ -eq 2 } { $res = Stop-AzVM -ResourceGroupName "VM-Projet-Powershell" -Name $VMMod; $mod = "Arrêtée" }
                Default {}
            }
            
            if ($res.Status -eq "Succeeded") {
                Write-Output "La VM $($VMMod) a été correctement $($mod)"
                
            }
            else {
                Write-Output "Il y a eu une erreur lors de la modification d'état de la VM"
                Write-Output "Voici l'erreur: $($res.Error)"
            }    
            
        }
        elseif ($NomOK -ne "True") {
            Write-Output "Le nom entré n'est pas correcte"
        }
        break
    }
    Read-Host -Prompt "Press any key to continue..."
}

############################################### VM SERVICE INSTALLATION ############################################
function InstallServiceVM {

    Write-Output "Voici la liste des machines virtuels: "
    $VMs = ListVM 
    $VMs | Format-Table -autosize -Property Nom, PowerState, OS, PrivateIpAddress, PublicIpAddress
    $VMInstall = read-host "Entrez le nom de la VM où installer le script: "
    foreach ($vm in $VMs) {
        if ($vm.Nom -eq $VMInstall) {
            $NomOK = "True"
            $Location = "NorthEurope"
            $resourceGroupe = "VM-Projet-Powershell"
            Write-Host "Veuillez entrer une URL public qui pointe vers le fichier de configuration (ex: repôt GitHub)" -ForegroundColor Yellow
            $fileURI = read-host "Entrez l'URL vers le fichier: "
            $fileName = read-host "Entrez le nom du fichier à exécuter: "

            $res = Set-AzVMCustomScriptExtension -ResourceGroupName $resourceGroupe `
                -VMName $VMInstall `
                -Location $Location `
                -FileUri $fileURI `
                -Run $fileName `
                -Name InstallServiceVM
                
            $res
        }
    }
    if ($NomOK -ne "True") {
        Write-Output "Le nom de la VM entrée n'est pas correcte"
    }
    Read-Host -Prompt "Press any key to continue..."
}

################################################### VM RDP CONNEXION ###############################################
function connexionRDP {
    Write-Output "Voici la liste des machines virtuels: "
    $VMs = ListVM 
    $VMs | Format-Table -autosize -Property Nom, PowerState, OS, PrivateIpAddress, PublicIpAddress
    $VMConnexion = read-host "Entrez le nom de la VM auquel se connecté: "
    foreach ($vm in $VMs) {
        if ($vm.Nom -eq $VMConnexion) {
            $IPpubVM = Get-AzPublicIpAddress -ResourceGroupName "VM-Projet-Powershell" -Name "$($VMConnexion)-PublicIP"
            mstsc /v:$($IPpubVM.IpAddress):3389
        }
        if ($NomOK -ne "True") {
            Write-Output "Le nom de la VM entrée n'est pas correcte"
        }
    }
    Read-Host -Prompt "Press any key to continue..."
}

################################################## VM WINRM CONNEXION ##############################################
function connexionWinRM {
    $VMs = ListVM | Where-Object { $_.PowerState -eq "VM running" } #Get all running VMs
    if ($VMs.Count -eq 0) { #If no VM running
        Write-Host "No VM running" -ForegroundColor Red #Write error message
        Read-Host -Prompt "Press any key to continue..." #Wait for user to press a key
        break
    }
    else
    {
        $VMs | Format-Table -Property Nom -AutoSize | Sort-Object -Property Nom # Display all running VMs
        $choixVM = read-host “Quelle VM voulez-vous utiliser ? ” # Ask user to choose a VM
        foreach ($vm in $VMs) { # For each VM
            if ($choixVM -eq $VMs.Nom) { # If the VM name is the same as the user input

                $VM = Get-AzVM -ResourceGroupName "VM-Projet-Powershell" -Name $choixVM # Get the VM
                $networkProfile = $VM.NetworkProfile.NetworkInterfaces.id.Split("/") | Select-Object -Last 1 # Get the network profile
                $publicIP = (Get-AzNetworkInterface -Name $networkProfile).IpConfigurations.PublicIpAddress.Id.Split("/") | Select-Object -Last 1 # Get the public IP
                $publicIPAddress = (Get-AzPublicIpAddress -Name $publicIP).IpAddress # Get the public IP address
                $connectionUri = "http://" + $publicIPAddress + ":5985" # Create the connection URI
    
                $username = Read-Host "Enter username" # Ask for username
                $pass = Read-Host "Enter password" -AsSecureString # Ask for password
                $cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $username, $pass # Create the credential
                Enter-PSSession -ConnectionUri $connectionUri -Credential $cred # Connect to the VM
            }
        }
    }
}

####################################################################################################################
################################################ BENCHMARKINGTOOL ##################################################
####################################################################################################################

################################################ BENCHMARKING TOOL #################################################

function BenchmarkingTool {
    param (
        [int]$decimals, # Number of decimals to calculate
        [int]$thread # Number of threads to use
    )
    $CalculatePiDecimals = { # Function to calculate Pi with a given number of decimals
        param($Limit) # Number of decimals to calculate
    
        $k = 0 # Number of iterations
        $pi = 0 # Pi value
        $sign = 1 # Sign of the current iteration
        while ($k -lt $Limit) { # Loop until the number of decimals is reached
            $pi = $pi + $sign * 4 / (2 * $k + 1) # Calculate Pi
            $k++ # Increment the number of iterations
            $sign *= -1 # Change the sign of the current iteration (1 -> -1 -> 1 -> -1 -> ...)
        } 
    }
    
    $result = Measure-Command { # Measure the time to calculate Pi with the given number of decimals and threads
        $MaxThreads = $thread # Number of physical threads to use
        $RunspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads) # Create a runspace pool with the given number of threads
        $RunspacePool.Open() # Open the runspace pool
        $Jobs = @() # Array to store the jobs
        
        1..$thread | Foreach-Object { # Loop for each logical thread
            Write-Host "Lancement du thread $_" -ForegroundColor Green # Display the current thread
            $PowerShell = [powershell]::Create() # Create a new PowerShell instance
            $PowerShell.RunspacePool = $RunspacePool # Set the runspace pool
            $PowerShell.AddScript($CalculatePiDecimals).AddArgument($decimals + 5) # Add the function to calculate Pi with the given number of decimals
            $Jobs += $PowerShell.BeginInvoke() # Start the job
        }
        
        while ($Jobs.IsCompleted -contains $false) { # Loop until all jobs are completed
            Start-Sleep -Milliseconds 100 # Wait 100ms
        }
    } | Select-Object TotalSeconds # Select the total time to calculate Pi
    $time = [math]::round($result.TotalSeconds, 2) # Round the time to 2 decimals
    Write-Host "Résultat : $time secondes" -ForegroundColor Yellow 
    return $time
}

################################################ START BENCHMARK ###################################################

function StartBenchmark {
    $VMs = ListVM | Where-Object { $_.PowerState -eq "VM running" } # Get all running VMs
    if ($VMs.Count -eq 0) { # If no VM running
        Write-Host "No VM running" -ForegroundColor Red # Display error message
        Read-Host -Prompt "Press any key to continue..." # Wait for user input
        break
    }
    else
    {
        $VMs | Format-Table -Property Nom -AutoSize | Sort-Object -Property Nom # Display all running VMs
        $choixVM = read-host “Quelle VM voulez-vous utiliser ? ” # Ask user to choose a VM
        if ($choixVM -eq $VMs.Nom) { # If the chosen VM is running

            $VM = Get-AzVM -ResourceGroupName "VM-Projet-Powershell" -Name $choixVM # Get the VM
            $networkProfile = $VM.NetworkProfile.NetworkInterfaces.id.Split("/") | Select-Object -Last 1 # Get the network profile
            $publicIP = (Get-AzNetworkInterface -Name $networkProfile).IpConfigurations.PublicIpAddress.Id.Split("/") | Select-Object -Last 1 # Get the public IP
            $publicIPAddress = (Get-AzPublicIpAddress -Name $publicIP).IpAddress # Get the public IP address
            $connectionUri = "http://" + $publicIPAddress + ":5985" # Create the connection URI

            $username = Read-Host "Enter username" # Ask user to enter VM's username
            $pass = Read-Host "Enter password" -AsSecureString # Ask user to enter VM's password
            $cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $username, $pass # Create the credential object

            Write-Host "Starting benchmarking tool" -foregroundColor DarkYellow 
            $s = New-PSSession -ConnectionUri $connectionUri -Credential $cred -SessionOption (New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck) # Create a new session

            $time = Invoke-Command -Session $s -ScriptBlock ${function:BenchmarkingTool} -ArgumentList 10000000, 1 # Invoke the benchmarking tool with default values

            Read-Host -Prompt "Press any key to continue..."

            $saveScore = $true # Set the save score variable to true
            while ($saveScore) { # While the user wants to save the score
                $choixSave = read-host “Voulez-vous sauvegarder votre score ? (yes/no)” # Ask user if he wants to save the score
                
                switch ($choixSave) { #
                    yes { # If the user wants to save the score

                        $CPUModel = Invoke-Command -Session $s -ScriptBlock { Get-WmiObject -Class Win32_Processor -ComputerName. | Select-Object -Property Name } # Get the CPU model of the benchmarked instance
                        Write-Host CPU Model : $CPUModel.Name -ForegroundColor DarkYellow # Display the CPU model

                        $CPU = Read-Host "Enter you CPU Model (empty to enter the previous model)" # Ask user to enter his CPU model or leave it empty to use the previous one
                        if ($CPU -eq "") { # If the user left the CPU model empty
                            $CPU = $CPUModel.Name # Use the previous CPU model
                        }
                        $score = [PSCustomObject]@{ # Create the score object
                            "CPU Model" = $CPU # Add the CPU model to the score object
                            "Time"      = $time # Add the time to the score object
                        }
                        $score | Export-Csv -Path '.\results\results.csv' -Append -NoTypeInformation # Save the score to the results file
                        Write-Host "Score saved" -ForegroundColor Green 

                        $saveScore = $false # Set the save score variable to false
                    }
                    no {
                        $saveScore = $false # Set the save score variable to false
                    }
                    default { Write-Host "Choix invalide" -ForegroundColor Red } # If the user entered an invalid choice
                }
            }
        }
    }
}

############################################### STANDARD STRESS TEST ###############################################
function StandardStressTest {
    $VMs = ListVM | Where-Object { $_.PowerState -eq "VM running" } # Get all running VMs
    if ($VMs.Count -eq 0) { # If no VM is running
        Write-Host "No VM running" -ForegroundColor Red # Display error message
        Read-Host -Prompt "Press any key to continue..." # Wait for user input
        break
    }
    else
    {
        $VMs | Format-Table -Property Nom -AutoSize | Sort-Object -Property Nom # Display all running VMs
        $choixVM = read-host “Quelle VM voulez-vous utiliser ? ” # Ask user to choose a VM
        if ($choixVM -eq $VMs.Nom) { # If the chosen VM is running

            $VM = Get-AzVM -ResourceGroupName "VM-Projet-Powershell" -Name $choixVM # Get the chosen VM
            $networkProfile = $VM.NetworkProfile.NetworkInterfaces.id.Split("/") | Select-Object -Last 1 # Get the network profile of the chosen VM
            $publicIP = (Get-AzNetworkInterface -Name $networkProfile).IpConfigurations.PublicIpAddress.Id.Split("/") | Select-Object -Last 1 # Get the public IP of the chosen VM
            $publicIPAddress = (Get-AzPublicIpAddress -Name $publicIP).IpAddress # Get the public IP address of the chosen VM
            $connectionUri = "http://" + $publicIPAddress + ":5985" # Create the connection URI

            $username = Read-Host "Enter username" # Ask user to enter VM's username
            $pass = Read-Host "Enter password" -AsSecureString # Ask user to enter VM's password
            $cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $username, $pass # Create credential object

            Write-Host "Starting benchmarking tool" -foregroundColor DarkYellow
            $s = New-PSSession -ConnectionUri $connectionUri -Credential $cred -SessionOption (New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck) # Create a new session

            # Get number of logical processors
            $thread = Invoke-Command -Session $s -ScriptBlock { (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors} # Get number of logical processors

            # Start benchmarking tool with the number of logical processors
            Invoke-Command -Session $s -ScriptBlock ${function:BenchmarkingTool} -ArgumentList 1000000000, $thread # Start benchmarking tool
        }
    }
}

############################################### ADVANCED STRESS TEST ###############################################
function AdvancedStressTest {

    $VMs = ListVM | Where-Object { $_.PowerState -eq "VM running" } # Get all running VMs
    if ($VMs.Count -eq 0) { # If no VM is running
        Write-Host "No VM running" -ForegroundColor Red # Display error message
        Read-Host -Prompt "Press any key to continue..." # Wait for user input
        break
    }
    else
    {
        $VMs | Format-Table -Property Nom -AutoSize | Sort-Object -Property Nom # Display all running VMs
        $choixVM = read-host “Quelle VM voulez-vous utiliser ? ” # Ask user to choose a VM
        if ($choixVM -eq $VMs.Nom) { # If the selected VM is running

            $VM = Get-AzVM -ResourceGroupName "VM-Projet-Powershell" -Name $choixVM # Get the selected VM object
            $networkProfile = $VM.NetworkProfile.NetworkInterfaces.id.Split("/") | Select-Object -Last 1 # Get the network profile of the selected VM
            $publicIP = (Get-AzNetworkInterface -Name $networkProfile).IpConfigurations.PublicIpAddress.Id.Split("/") | Select-Object -Last 1 # Get the public IP of the selected VM
            $publicIPAddress = (Get-AzPublicIpAddress -Name $publicIP).IpAddress # Get the public IP address of the selected VM
            $connectionUri = "http://" + $publicIPAddress + ":5985" # Create the connection URI

            $username = Read-Host "Enter username" # Ask user to enter VM's username
            $pass = Read-Host "Enter password" -AsSecureString # Ask user to enter VM's password
            $cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $username, $pass # Create the credential object

            $inputValue = 0 # Initialize the input value
            do { # Loop until the user enters a positive integer
                $inputValid = [uint]::TryParse(($threads = Read-Host 'How much threads do you want to use?'), [ref]$inputValue) # As to be check when 0 is entered
                if (-not $inputValid) {
                    Write-Host "your input was not a positive integer..." -ForegroundColor Red
                }
            } while (-not $inputValid) 
    
            $inputValue = 0 # Initialize the input value
            do { # Loop until the user enters a positive integer
                $inputValid = [uint]::TryParse(($decimals = Read-Host 'How much Pi decimals you want to calculate? (default is 10000000)'), [ref]$inputValue)
                if (-not $inputValid) {
                    Write-Host "your input was not a positive integer..." -ForegroundColor Red
                }
            } while (-not $inputValid)
            
            Write-Host "Starting advanced stress test" -foregroundColor DarkYellow 
            $s = New-PSSession -ConnectionUri $connectionUri -Credential $cred -SessionOption (New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck) # Create a new session

            # Start advanced stress test with the number of logical processors and decimals
            Invoke-Command -Session $s -ScriptBlock ${function:BenchmarkingTool} -ArgumentList $decimals, $threads
        }
    }
}

##################################################################################################################
##################################################### MAIN #######################################################
##################################################################################################################

$continue = $true

function main {
    $resourceGroup = Get-AzResourceGroup
    if ($resourceGroup.ResourceGroupName -eq "VM-Projet-Powershell") {
        while ($continue) {
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

            write-host "`n-------------------- Deploy a VM on Azure --------------------" -ForegroundColor Cyan
            write-host "1. Create a VM" -ForegroundColor Cyan
            write-host "2. List existing VM" -ForegroundColor Cyan
            write-host "3. Remove a VM" -ForegroundColor Cyan
            write-host "4. Start/stop a VM" -ForegroundColor Cyan
            write-host "5. Install a service" -ForegroundColor Cyan
            write-host "6. Connect to a VM with RDP" -ForegroundColor Cyan
            write-host "7. Connect to a VM with WinRM" -ForegroundColor Cyan

            write-host "`n--------------- Benchmark/Stress the instance ----------------" -ForegroundColor Green
            write-host "8. Show the comparison results" -ForegroundColor Green
            write-host "9. Start the benchmark (single thread)" -ForegroundColor Green
            write-host "10. Start a stress test (all cores)" -ForegroundColor Green
            write-host "11. Start an advanced stress test" -ForegroundColor Green

            write-host "`nx. exit`n" -ForegroundColor Magenta

            $choix = read-host “faire un choix ”
            switch ($choix) {
                1 { creationVM }
                2 { 
                    $ListVM = ListVM
                    $ListVM | Format-Table -Property Nom, PowerState, OS, PrivateIpAddress, PublicIpAddress -AutoSize | Sort-Object -Property Length
                }
                3 { supprimerVM }
                4 { GestionVM }
                5 { InstallServiceVM }
                6 { connexionRDP }
                7 { connexionWinRM }
                ########################################
                8 {
                    write-host "Scoreboard (seconds)" -ForegroundColor DarkYellow
                    $scoreBoard = Import-Csv -Path '.\results\results.csv' | Sort-Object { [int]$_.Time }
                    $scoreBoard | Format-Table -AutoSize
                }
                9 { StartBenchmark }
                10 { StandardStressTest }
                11 { AdvancedStressTest }
                ########################################
                ‘x’ { $continue = $false }
                default { Write-Host "Choix invalide" -ForegroundColor Red }
            }
            Read-Host -Prompt "Press any key to continue..."
        }
    }
    else {
        Write-Host "Pour que le script fonctionne, il faut que le ressource group VM-Projet-Powershell existe" -foregroundcolor red
        Write-Host "Voulez-vous le créer ? (yes/no)" -foregroundcolor red
        $choixRG = Read-Host
        switch ($choixRG) {
            yes {
                $RG = New-AzResourceGroup -Name "VM-Projet-Powershell" -Location "NorthEurope"
                Write-Host "Ressource group créé" -ForegroundColor Green
                main                
            }
            no {
                Write-Host "Annulation..." 
                exit
            }
            default { Write-Host "Choix invalide" -ForegroundColor Red }
        }
    }
}

main