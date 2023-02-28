Write-Output "Connexion à l'environnement Azure:"
$auth = Connect-AzAccount #On laisse l'authentification à chaque lancement du script pour plus de sécurité et pour laisser l'utilisateur choisir sont tenant si il doit déployer plusieurs VM sur différents tenant


function creationVM {
    #Récupérer les informations d'authentification pour la connexion à la machine
<#
    $ComputerName = read-host "Entrez le nom de la VM"
    $Location = "NorthEurope"
    $resourceGroupe = "VM-Projet-Powershell"
    $VMSize="Standard_B1s"
    $ImageName="MicrosoftWindowsServer:WindowsServer:2016-Datacenter-with-Containers:latest"
    $virtualNetwork = "VM-Projet-Powershell-$($ComputerName)"
    $cred = Get-Credential
    $IPpublique = New-AzPublicIpAddress -Name "VM-Projet-Powershell-IP-$($ComputerName)" -ResourceGroupName $resourceGroupe -AllocationMethod Static -Location $Location


    New-AzVm `
        -ResourceGroupName $resourceGroupe `
        -Name $ComputerName `
        -Location $Location `
        -VirtualNetworkName $virtualNetwork `
        -ImageName $ImageName `
        -Size $VMSize `
        -Credential $cred 
        #-PublicIpAddressId $IPpublique.Id #test IP pub
        #-PublicIpAddressName $IPpublique.Name `
        #-OpenPorts 3389,5985 `

#>

    New-AzResourceGroupDeployment -ResourceGroupName "VM-Projet-Powershell" -TemplateUri ./templates/azuredeploy.json -DeploymentDebugLogLevel All -Verbose

    }

function ListVM{
    $VMs = Get-AzVM -ResourceGroupName "VM-Projet-Powershell"
    $global:VMObject = @()

    write-Output "La liste des Machines virtuelles"
    foreach ($VM in $VMs){
        write-output "-------Machine Virtuelle-------"
        Write-Output "Nom: $($VM.Name)"
        Write-Output "OS: $($VM.OsType)"
        Write-Output "Status: $($VM.StatusCode)"
        $global:VMObject += @($VM.Name)
    }
}



function SupprimerVM {
    Write-Output "Voici la liste des machines virtuels: "
    $global:VMObject
    $VMDel = read-host "Entrez le nom de la VM à supprimer: "
    foreach ($vm in $VMObject){
        if ($vm -eq $VMDel){
            $NomOK = "True"
            $res = Remove-AzVM -ResourceGroupName "VM-Projet-Powershell" -Name $VMDel
            Remove-AzPublicIpAddress -ResourceGroupName "VM-Projet-Powershell" -Name "$($VMDel)-PublicIP"
            
            if ($res.Status -eq "Succeeded") {
                Write-Output "La VM $($VMDel) à été correctement supprimé"
            }
            else {
                Write-Output "Il y a eu une erreur dans la suppression de la VM"
            }
        }
    }
    if ($NomOK -ne "True"){
        Write-Output "Le nom entré n'est pas correcte"
    }
    
}

function GestionVM {
    Write-Output "Voici la liste des machines virtuels: "
    $global:VMObject
    $VMMod = read-host "Entrez le nom de la VM à gérer: "
    foreach ($vm in $VMObject){
        if ($vm -eq $VMMod){
            $NomOK = "True"
            $rep = read-host "
            Que voulez-vous faire?
            1. Démarrer la VM
            2. Éteindre la VM
            "
            switch ($rep){
                { $_ -eq 1 } { $res = Start-AzVM -ResourceGroupName "VM-Projet-Powershell" -Name $VMMod; $mod = "Démarré"}
                { $_ -eq 2 } { $res = Stop-AzVM -ResourceGroupName "VM-Projet-Powershell" -Name $VMMod; $mod = "Arrêté"}
                Default {}
            }
            
            if ($res.Status -eq "Succeeded") {
                Write-Output "La VM $($VMMod) à été correctement $($mod)"
                
            }
            else {
                Write-Output "Il y a eu une erreur lors de la modification d'état de la VM"
                Write-Output "Voici l'erreur: $($res.Error)"
            }    
            
        }
        elseif ($NomOK -ne "True"){
            Write-Output "Le nom entré n'est pas correcte"
        }
        break
    }


}

function InstallServiceVM {

    Write-Output "Voici la liste des machines virtuels: "
    $global:VMObject
    $VMInstall = read-host "Entrez le nom de la VM où installer le script: "
    foreach ($vm in $VMObject){
        if ($vm -eq $VMInstall){
            $NomOK = "True"
            $Location = "NorthEurope"
            $resourceGroupe = "VM-Projet-Powershell"
            Write-Host "Veuillez entré une URL public qui pointe vers le fichier de configuration (ex: repôt GitHub)" -ForegroundColor Yellow
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
    if ($NomOK -ne "True"){
        Write-Output "Le nom de la VM entrée n'est pas correcte"
    }
}

function connexionRDP {
    Write-Output "Voici la liste des machines virtuels: "
    $global:VMObject
    $VMConnexion = read-host "Entrez le nom de la VM auquel se connecté: "
    foreach ($vm in $VMObject){
        if ($vm -eq $VMConnexion){
            $IPpubVM = Get-AzPublicIpAddress -ResourceGroupName "VM-Projet-Powershell" -Name "$($VMConnexion)-PublicIP"
            Write-Output "all"
            $IPpubVM
            Write-Output "ip"
            $IPpubVM.IpAddress
            mstsc /v:$IPpubVM.IpAddress:3389

        }
        if ($NomOK -ne "True"){
            Write-Output "Le nom de la VM entrée n'est pas correcte"
        }
    }

}


function main {
    $resourceGroup = Get-AzResourceGroup
    if ($resourceGroup.ResourceGroupName -eq "VM-Projet-Powershell")
    {

        while ($rep -ne 0) {

            $rep = read-host "
                Que voulez-vous faire?
                1. Création d'une VM
                2. Lister les VM existantes
                3. Supprimer une VM
                4. Arreter ou démarrer une VM
                5. Installation de service
                6. Connexion RDP
                0. Quiter le script
                "
            switch ($rep){
                { $_ -eq 1 } { creationVM }
                { $_ -eq 2 } { $ListVM = ListVM ; $ListVM}
                { $_ -eq 3 } { SupprimerVM }
                { $_ -eq 4 } { GestionVM }
                { $_ -eq 5 } { InstallServiceVM }
                { $_ -eq 6 } { connexionRDP }
                Default {}
            }
        }
    }
    else 
    {
        Write-Host "Pour que le script fonctionne, il faut que le ressource group VM-Projet-Powershell existe" -foregroundcolor red
        Write-Host "Voulez-vous le créer ? (yes/no)" -foregroundcolor red
        $choixRG = Read-Host
        switch ($choixRG){
            yes {
                $RG = New-AzResourceGroup -Name "VM-Projet-Powershell" -Location "NorthEurope"
                Write-Host "Ressource group créé" -ForegroundColor Green
                main
                
            }
            no {
                Write-Host "Annulation..." 
                exit
            }
            default {Write-Host "Choix invalide" -ForegroundColor Red}
        }
    }
}

main