Connect-AzAccount
Connect-AzAccount -TenantId c371d4f5-b34f-4b06-9e66-517fed904220
$username = 'Administrateur' 
$password = ConvertTo-SecureString 'ESGIProjet2023*' -AsPlainText -Force
$AzVMWindowsCredentials = New-Object System.Management.Automation.PSCredential ($username, $password)
New-AzVm `
    -ResourceGroupName 'ProjetPowershell' `
    -Name 'SRV-AD' `
    -Location 'East US' `
    -VirtualNetworkName 'myVnet' `
    -SubnetName 'mySubnet' `
    -SecurityGroupName 'myNetworkSecurityGroup' `
    -PublicIpAddressName 'myPublicIpAddress' `
    -OpenPorts 80,3389
    Get-AzPublicIpAddress 
    -ResourceGroupName 'ProjetPowershell' 
    -Name 'SRV-AD' | Select-Object IpAddress