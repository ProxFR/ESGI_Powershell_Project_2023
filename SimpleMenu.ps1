Write-Output "Connexion à l'environnement Azure:"
$auth = Connect-AzAccount #On laisse l'authentification à chaque lancement du script pour plus de sécurité et pour laisser l'utilisateur choisir sont tenant si il doit déployer plusieurs VM sur différents tenant

##################################################################################################################
################################################ BENCHMARKINGTOOL ################################################
##################################################################################################################

function creationVM {
    #Récupérer les informations d'authentification pour la connexion à la machine

    New-AzResourceGroupDeployment -ResourceGroupName "VM-Projet-Powershell" -TemplateUri ./templates/azuredeploy.json -DeploymentDebugLogLevel All -Verbose

}

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



function SupprimerVM {
    Write-Output "Voici la liste des machines virtuels: "
    $VMs = ListVM 
    $VMs | Format-Table -autosize -Property Nom, PowerState, OS, PrivateIpAddress, PublicIpAddress
    $VMDel = read-host "Entrez le nom de la VM à supprimer: "
    foreach ($vm in $VMs) {
        if ($vm.Nom -eq $VMDel) {
            $NomOK = "True"
            $vm = Get-AzVm -Name $VMDel -ResourceGroupName "VM-Projet-Powershell"
            $res = Remove-AzVM -ResourceGroupName "VM-Projet-Powershell" -Name $VMDel -Verbose
            foreach ($nicUri in $vm.NetworkProfile.NetworkInterfaces.Id) {
                $nic = Get-AzNetworkInterface -ResourceGroupName $vm.ResourceGroupName -Name $nicUri.Split('/')[-1]
                Remove-AzNetworkInterface -Name $nic.Name -ResourceGroupName $vm.ResourceGroupName -Force
            
                foreach ($ipConfig in $nic.IpConfigurations) {
                    if ($ipConfig.PublicIpAddress -ne $null) {
                        Remove-AzPublicIpAddress -ResourceGroupName $vm.ResourceGroupName -Name $ipConfig.PublicIpAddress.Id.Split('/')[-1] -Force
                    }
                }
            }
            $pattern = $($VMDel) + '.*(D|d)isk.*([0-9]|[a-z]){32}$'
            $DiskName = get-AzDisk -ResourceGroupName "VM-Projet-Powershell" | Select-Object -Property Name | Select-String -Pattern $pattern -verbose
            Write-Output "valeur de diskname:"
            $DiskName
            $DiskName.Replace('@{name=', '')
            $DiskName.Replace('}', '')
            $DiskName
            Remove-AzDisk -ResourceGroupName "VM-Projet-Powershell" -DiskName $DiskName -Force -Verbose

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

function connexionRDP {
    Write-Output "Voici la liste des machines virtuels: "
    $VMs = ListVM 
    $VMs | Format-Table -autosize -Property Nom, PowerState, OS, PrivateIpAddress, PublicIpAddress
    $VMConnexion = read-host "Entrez le nom de la VM auquel se connecté: "
    foreach ($vm in $VMs) {
        write-host $vm.Nom
        if ($vm.Nom -eq $VMConnexion) {
            $IPpubVM = Get-AzPublicIpAddress -ResourceGroupName "VM-Projet-Powershell" -Name "$($VMConnexion)-PublicIP"
            Write-Output "all"
            $IPpubVM
            Write-Output "ip"
            $IPpubVM.IpAddress
            mstsc /v:$($IPpubVM.IpAddress):3389

        }
        if ($NomOK -ne "True") {
            Write-Output "Le nom de la VM entrée n'est pas correcte"
        }
    }
    Read-Host -Prompt "Press any key to continue..."
}

function connexionWinRM {
    $VMs = ListVM | Where-Object { $_.PowerState -eq "VM running" }
    if ($VMs.Count -eq 0) {
        Write-Host "No VM running" -ForegroundColor Red
        Read-Host -Prompt "Press any key to continue..."
        break
    }
    else
    {
        $VMs | Format-Table -Property Nom -AutoSize | Sort-Object -Property Nom
        $choixVM = read-host “Quelle VM voulez-vous utiliser ? ”
        if ($choixVM -eq $VMs.Nom) {

            $VM = Get-AzVM -ResourceGroupName "VM-Projet-Powershell" -Name $choixVM
            $networkProfile = $VM.NetworkProfile.NetworkInterfaces.id.Split("/") | Select-Object -Last 1
            $publicIP = (Get-AzNetworkInterface -Name $networkProfile).IpConfigurations.PublicIpAddress.Id.Split("/") | Select-Object -Last 1
            $publicIPAddress = (Get-AzPublicIpAddress -Name $publicIP).IpAddress
            $connectionUri = "http://" + $publicIPAddress + ":5985"

            $username = Read-Host "Enter username"
            $pass = Read-Host "Enter password" -AsSecureString 
            $cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $username, $pass
            Enter-PSSession -ConnectionUri $connectionUri -Credential $cred
        }    
    }
}

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
    $time = [math]::round($result.TotalSeconds, 2)
    Write-Host "Résultat : $time secondes" -ForegroundColor Yellow
    return $time
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
                1 { 
                    creationVM
                    Read-Host -Prompt "Press any key to continue..." 
                }
                2 { 
                    $ListVM = ListVM
                    $ListVM | Format-Table -Property Nom, PowerState, OS, PrivateIpAddress, PublicIpAddress -AutoSize | Sort-Object -Property Length
                    Read-Host -Prompt "Press any key to continue..." 
                }
                3 { 
                    supprimerVM
                    Read-Host -Prompt "Press any key to continue..." 
                }
                4 { 
                    GestionVM
                    Read-Host -Prompt "Press any key to continue..." 
                }
                5 { 
                    InstallServiceVM
                    Read-Host -Prompt "Press any key to continue..." 
                }
                6 { 
                    connexionRDP
                    Read-Host -Prompt "Press any key to continue..." 
                }
                7 { 
                    connexionWinRM
                    Read-Host -Prompt "Press any key to continue..." 
                }
                ########################################
                8 {
                    write-host "Scoreboard (seconds)" -ForegroundColor DarkYellow
                    $scoreBoard = Import-Csv -Path '.\results\results.csv' | Sort-Object { [int]$_.Time }
                    $scoreBoard | Format-Table -AutoSize
                    Read-Host -Prompt "Press any key to continue..."
                }
                9 {
                    
                    $VMs = ListVM | Where-Object { $_.PowerState -eq "VM running" }
                    if ($VMs.Count -eq 0) {
                        Write-Host "No VM running" -ForegroundColor Red
                        Read-Host -Prompt "Press any key to continue..."
                        break
                    }
                    else
                    {
                        $VMs | Format-Table -Property Nom -AutoSize | Sort-Object -Property Nom
                        $choixVM = read-host “Quelle VM voulez-vous utiliser ? ”
                        foreach ($vm in $VMs) {

                            if ($choixVM -eq $vm.Nom) {

                                $VMSelected = Get-AzVM -ResourceGroupName "VM-Projet-Powershell" -Name $vm.Nom
                                $networkProfile = $VMSelected.NetworkProfile.NetworkInterfaces.id.Split("/") | Select-Object -Last 1
                                $publicIP = (Get-AzNetworkInterface -Name $networkProfile).IpConfigurations.PublicIpAddress.Id.Split("/") | Select-Object -Last 1
                                $publicIPAddress = (Get-AzPublicIpAddress -Name $publicIP).IpAddress
                                $connectionUri = "http://" + $publicIPAddress + ":5985"

                                $username = Read-Host "Enter username"
                                $pass = Read-Host "Enter password" -AsSecureString 
                                $cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $username, $pass

                                Write-Host "Starting benchmarking tool" -foregroundColor DarkYellow
                                $s = New-PSSession -ConnectionUri $connectionUri -Credential $cred -SessionOption (New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck)
            
                                $time = Invoke-Command -Session $s -ScriptBlock ${function:BenchmarkingTool} -ArgumentList 10000000, 1

                                Read-Host -Prompt "Press any key to continue..."
            
                                $saveScore = $true
                                while ($saveScore) {
                                    $choixSave = read-host “Voulez-vous sauvegarder votre score ? (yes/no)”

                                    # Get CPU model of the benchmarked instance
                                    $CPUModel = Invoke-Command -Session $s -ScriptBlock { Get-WmiObject -Class Win32_Processor -ComputerName. | Select-Object -Property Name }
                                    Write-Host CPU Model : $CPUModel.Name -ForegroundColor DarkYellow
                                    
                                    switch ($choixSave) {
                                        yes {
                                            $CPU = Read-Host "Enter you CPU Model (empty to enter the previous model)"
                                            if ($CPU -eq "") {
                                                $CPU = $CPUModel.Name
                                            }
                                            $score = [PSCustomObject]@{
                                                "CPU Model" = $CPU
                                                "Time"      = $time
                                            }
                                            $score | Export-Csv -Path '.\results\results.csv' -Append -NoTypeInformation
                                            Write-Host "Score saved" -ForegroundColor Green
            
                                            $saveScore = $false
                                            Read-Host -Prompt "Press any key to continue..."
                                        }
                                        no {
                                            $saveScore = $false
                                        }
                                        default { Write-Host "Choix invalide" -ForegroundColor Red }
                                    }
                                }
                            }
                        }
                    }
                }
                10 {
                    Write-Host "Starting stress test" -foregroundColor DarkYellow
                    powershell.exe -File .\scripts\StressTool_Thread.ps1 # Start inside a new terminal to permit user to stop run space (CTRL+C)
                    Read-Host -Prompt "Press any key to continue..."
                }
                11 {
                    $inputValue = 0
                    do {
                        $inputValid = [uint]::TryParse(($threads = Read-Host 'How much threads do you want to use?'), [ref]$inputValue) # As to be check when 0 is entered
                        if (-not $inputValid) {
                            Write-Host "your input was not a positive integer..." -ForegroundColor Red
                        }
                    } while (-not $inputValid)

                    $inputValue = 0
                    do {
                        $inputValid = [uint]::TryParse(($decimals = Read-Host 'How much Pi decimals you want to calculate? (default is 10000000)'), [ref]$inputValue)
                        if (-not $inputValid) {
                            Write-Host "your input was not a positive integer..." -ForegroundColor Red
                        }
                    } while (-not $inputValid)

                    Write-Host "Starting stress test" -foregroundColor DarkYellow
                    powershell.exe -File .\scripts\StressTool_Thread.ps1 -decimals $decimals -thread $threads # Start inside a new terminal to permit user to stop run space (CTRL+C)
                    Read-Host -Prompt "Press any key to continue..."
                }
                ########################################
                ‘x’ { $continue = $false }
                default { Write-Host "Choix invalide" -ForegroundColor Red }
            }
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