##############################################################################
################################# WINRM ######################################
##############################################################################

netsh advfirewall set allprofiles state off

##############################################################################
############################# GRAFANA AGENT ##################################
##############################################################################


# # Create file where grafana agent will be download
# New-Item -ItemType Directory -Path C:\Script\InstallAgentGrafana

# $path = "C:\Script\InstallAgentGrafana"

# Set-Location $path

# # Install Module Powershell-yaml required to convert agent config from json to yaml
# Write-Host "Checking and installing required Powershell-yaml module"
# Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser
# Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
# Install-Module PowerShell-yaml

# # Script to install Grafana agent for Windows
# $GCLOUD_STACK_ID = "540562"
# $GCLOUD_API_KEY = "eyJrIjoiNzE1YzU1NzI2ZGU2OTY4ZTZmYjEzNDJjYTYyYjIwZmY3YmJhNzU1OCIsIm4iOiJzdGFjay01NDA1NjItZWFzeXN0YXJ0LWdjb20iLCJpZCI6NzkxMzEzfQ=="
# $GCLOUD_API_URL = "https://integrations-api-eu-west.grafana.net"

# Write-Host "Setting up Grafana agent"

# # Check if required parameters are present
# if ($GCLOUD_STACK_ID -eq "") {
#   Write-Host "ERROR: Required argument GCLOUD_STACK_ID missing"
#   exit
# }

# if ($GCLOUD_API_KEY -eq "") {
#   Write-Host "ERROR:  Required argument GCLOUD_API_KEY missing"
#   exit
# }

# if ($GCLOUD_API_URL -eq "") {
#   Write-Host "ERROR: Required argument GCLOUD_API_URL missing"
#   exit
# }

# Write-Host "GCLOUD_STACK_ID:" $GCLOUD_STACK_ID
# Write-Host "GCLOUD_API_KEY:" $GCLOUD_API_KEY
# Write-Host "GCLOUD_API_URL:" $GCLOUD_API_URL

# Write-Host "Downloading Grafana agent Windows Installer"
# $DOWLOAD_URL = "https://github.com/grafana/agent/releases/latest/download/grafana-agent-installer.exe.zip"
# $OUTPUT_ZIP_FILE = ".\grafana-agent-installer.exe.zip"
# $OUTPUT_FILE = ".\grafana-agent-installer.exe"
# Invoke-WebRequest -Uri $DOWLOAD_URL -OutFile $OUTPUT_ZIP_FILE
# Expand-Archive -LiteralPath $OUTPUT_ZIP_FILE -DestinationPath $OUTPUT_FILE

# # Install Grafana agent in silent mode
# Write-Host "Installing Grafana agent for Windows"
# .\grafana-agent-installer.exe\grafana-agent-installer.exe /S

# Write-Host "Retrieving and updating Grafana agent config"
# $CONFIG_URI = "$GCLOUD_API_URL/stacks/$GCLOUD_STACK_ID/agent_config?platforms=windows"
# $AUTH_TOKEN = "Bearer $GCLOUD_API_KEY"

# $headers = @{
#     Authorization = $AUTH_TOKEN
# }

# $response = Invoke-WebRequest $CONFIG_URI -Method 'GET' -Headers $headers -UseBasicParsing

# $jsonObj = $response | ConvertFrom-Json
# if ($jsonObj.status -eq "success") {
#   $config_file = ".\agent-config.yaml"
#   Write-Host "Saving and updating agent configuration file"
#   $yamlConfig = $jsonObj.data | ConvertTo-Yaml
#   Set-Content -Path $config_file -Value ($yamlConfig)
#     # Append APPDATA path to bookmark files
#     $line = Get-Content $config_file | Select-String bookmark_path | Select-Object -ExpandProperty Line
#     if ($line -ne $null) {
#         $content = Get-Content $config_file
#         $line | ForEach-Object {
#             $split_line = $_ -split ": "
#             $prefix = $split_line[0]
#             $bookmark_filename = $split_line[1] -replace "./",""
#             $content = $content -replace $_,"$($prefix): $($env:APPDATA)\$($bookmark_filename)"
#         }
#         $content | Set-Content $config_file
#     }
#     Move-Item $config_file "C:\Program Files\Grafana Agent\agent-config.yaml" -force

#   # Wait for service to initialize after first install
#   Write-Host "Wait for Grafana service to initialize"
#   Start-Sleep -s 5

#   # Restart Grafana agent to load new configuration
#   Write-Host "Restarting Grafana agent service"
#   Stop-Service "Grafana Agent"
#   Start-Service "Grafana Agent"

#   # Wait for service to startup after restart
#   Write-Host "Wait for Grafana service to initialize after restart"
#   Start-Sleep -s 10

#   # Show Grafana agent service status
#   Get-Service "Grafana Agent"
# } else {
#   Write-Host "Failed to retrieve config"
# }