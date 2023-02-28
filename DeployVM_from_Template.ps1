Write-Output "Connexion à l'environnement Azure:"
$auth = Connect-AzAccount

$resourceGroup = Get-AzResourceGroup
if ($resourceGroup.ResourceGroupName -eq "VM-Projet-Powershell") 
{
    New-AzResourceGroupDeployment -ResourceGroupName "VM-Projet-Powershell" -TemplateUri .\templates\azuredeploy.json -DeploymentDebugLogLevel All -Verbose
}
else 
{
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
            Write-Host "Annulation..." -ForegroundColor Red
            exit
        }
        default { Write-Host "Choix invalide" -ForegroundColor Red }
    }
}