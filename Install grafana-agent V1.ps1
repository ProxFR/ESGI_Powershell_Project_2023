# Connexion à l'API Graph
$applicationId = ID
$tenantId = ID
$secret = ID
$subscriptionId = ID

# Variable permettant de lister les vm qui existent dans Azure de type Windows uniquement
$vm = Get-AzVM -ResourceGroupName "ProjetPowershell" AND -OsType "Windows"

# Boucle pour installer grafana agent pour toutes les vm disponibles
foreach ($singleVM in $vm) {
  Write-Host "Installation de l'agent Grafana sur $($singleVM.Name)..."
  $result = Invoke-Command -ComputerName $singleVM.Name -ScriptBlock {
    # Code pour installer Grafana-Agent sur la machine virtuelle actuelle
    curl -L https://raw.githubusercontent.com/grafana/agent/release/production/grafanacloud-install.ps1 --output grafanacloud-install.ps1
    powershell -executionpolicy Bypass -File ".\grafanacloud-install.ps1" -GCLOUD_STACK_ID "532357" -GCLOUD_API_KEY "eyJrIjoiNmJlOGI5ZmU0ZmU0YjRhODgxMDgwZjE5YzdhMGY4OWQ1M2Q2YzZiZiIsIm4iOiJzdGFjay01MzIzNTctZWFzeXN0YXJ0LWdjb20iLCJpZCI6NzkxMzEzfQ==" -GCLOUD_API_URL "https://integrations-api-eu-west.grafana.net"
    # Retourne un résultat indiquant si l'installation a réussi ou non
    return $true
  }
  if ($result) {
    Write-Host "L'agent Grafana-Agent a correctement été installé sur $($singleVM.Name)."
  } else {
    Write-Host "L'agent Grafana-Agent n'a pas correctement été installé sur $($singleVM.Name)."
  }
}
    
#Sources :
# https://www.it-connect.fr/powershell-comment-se-connecter-a-microsoft-graph-api/
# https://learn.microsoft.com/en-us/powershell/module/az.compute/get-azvm?view=azps-9.4.0
# https://www.it-connect.fr/supervisez-votre-serveur-rapidement-avec-grafana-cloud/
# chatgpt ;-)