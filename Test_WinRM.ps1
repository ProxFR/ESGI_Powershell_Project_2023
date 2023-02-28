# As admin
#winrm set winrm/config/client '@{TrustedHosts = "10.0.0.125"}'

function pingTest {
    ping google.fr
}

$username = Read-Host "Enter username"
$pass = Read-Host "Enter password" -AsSecureString 
$cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $username, $pass
#$s = New-PSSession -ConnectionUri 'http://23.102.34.8:5985' -Credential $cred -SessionOption (New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck)
Enter-PSSession -ConnectionUri 'http://23.102.34.8:5985' -Credential $cred

#Invoke-Command -Session $s -ScriptBlock ${function:pingTest}