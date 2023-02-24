Write-Output "Connexion à l'environnement Azure:"
$auth = Connect-AzAccount #On laisse l'authentification à chaque lancement du script pour plus de sécurité et pour laisser l'utilisateur choisir sont tenant si il doit déployer plusieurs VM sur différents tenant


function creationVM {
    #Récupérer les informations d'authentification pour la connexion à la machine

    $ComputerName = read-host "Entrez le nom de la VM"
    $Location = "NorthEurope"
    $ServiceName ="MonCloudapp"
    $resourceGroupe = "VM-Projet-Powershell"
    $VMSize="Standard_B1s"
    $ImageName="MicrosoftWindowsServer:WindowsServer:2016-Datacenter-with-Containers:latest"
    $NumberOfDisks=8
    $DiskSize=200
    $SubnetName="default"
    $virtualNetwork = "VM-Projet-Powershell-$($ComputerName)"
    $MediaLocation="https://xxxxxxx.blob.core.windows.net/vhds"
    $cred = Get-Credential

    # Create a public IP address
    #$publicIpName = "myPublicIp-" + $ComputerName
    #$publicIp = New-AzPublicIpAddress -ResourceGroupName $resourceGroupe -Name $publicIpName.toLowerCase() -Location $Location -AllocationMethod Static -DomainNameLabel $publicIpName.toLowerCase()

    # Create a network interface
    #$nicName = "NIC-" + $ComputerName
    #$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location "West US" -SubnetId $subnet.Id -PublicIpAddressId $publicIp.Id

    New-AzVm `
        -ResourceGroupName $resourceGroupe `
        -Name $ComputerName `
        -Location $Location `
        -PublicIpSku "Standard" `
        -VirtualNetworkName $virtualNetwork `
        -ImageName $ImageName `
        -Size $VMSize `
        -Credential $cred `
        #-PublicIpAddressId $publicIp.Id #test IP pub
        #-SubnetName $SubnetName `
        #-SecurityGroupName "myNetworkSecurityGroup" `
        #-PublicIpAddressName "myPublicIpAddress" `
    
}

function ListVM{
    $VMs = Get-AzVM -ResourceGroupName "VM-Projet-Powershell"
    $VMObject = @()

    foreach ($VM in $VMs){
        $VMObject += [PSCustomObject]@{
            Name = $VM.Name
            OS = $VM.OsType
            Status = $VM.StatusCode
            #IP = $VM.PublicIps
        }
    }
    return $VMObject


}

function SupprimerVM {
    Write-Output "Voici la liste des machines virtuels: "
    $listVM = ListVM
    $ListVM
    $VMDel = read-host "Entrez le nom de la VM à supprimer: "
    foreach ($vm in $ListVM){
        if ($vm.Name -eq $VMDel){
            $NomOK = "True"
            $res = Remove-AzVM -ResourceGroupName "VM-Projet-Powershell" -Name $VMDel
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
    $listVM = ListVM
    $ListVM
    $VMMod = read-host "Entrez le nom de la VM à gérer: "
    foreach ($vm in $ListVM){
        if ($vm.Name -eq $VMMod){
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
    }
    if ($NomOK -ne "True"){
        Write-Output "Le nom entré n'est pas correcte"
    }

}

function InstallServiceVM {

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
                0. Quiter le script
                "
            switch ($rep){
                { $_ -eq 1 } { creationVM }
                { $_ -eq 2 } { $ListVM = ListVM ; $ListVM }
                { $_ -eq 3 } { SupprimerVM }
                { $_ -eq 4 } { GestionVM }
                { $_ -eq 5 } { InstalServiceVM }
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
                Write-Host "Annulation..." -ForegroundColor Red
                exit
            }
            default {Write-Host "Choix invalide" -ForegroundColor Red}
        }
    }
}

main