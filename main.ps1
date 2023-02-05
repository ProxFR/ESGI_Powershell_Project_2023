Write-Output "Connexion à l'environnement Azure:"
Connect-AzAccount

function creationVM {

    param(
        [String] $VMName

    )

    #Récupérer les informations d'authentification pour la connexion à la machine
    $Location = "North Europe"
    $ComputerName = "MonSqlServer"
    $ServiceName ="MonCloudapp"
    $InstanceSize="A6"
    $ImageName="fb83b3509582419d99629ce476bcb5c8__SQL-Server-2014RTM-12.0.2000.8-Standard-ENU-WS2012R2-AprilGA"
    $NumberOfDisks=8
    $DiskSize=200
    $SubnetName="Subnet-1"
    $MediaLocation="https://XXXXXXX.blob.core.windows.net/vhds"
    $credential = Get-Credential

}

function ListVM{

}

function SupprimerVM {

}

function GestionVM {

}

function InstalServiceVM {

}


function main {

    $rep = read-host "Que voulez-vous faire?/n
    1. Création d'une VM
    2. Lister les VM existantes
    3. Supprimer une VM
    4. Arreter ou démarrer une VM
    5. Installation de service"
    
    switch ($rep){
        { $_ -eq 1 } { creationVM }
        { $_ -eq 2 } { ListVM }
        { $_ -eq 3 } { SupprimerVM }
        { $_ -eq 4 } { GestionVM }
        { $_ -eq 5 } { InstalServiceVM }
    }

}