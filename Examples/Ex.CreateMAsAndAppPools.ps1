# Create Managed Accounts and Application Pools

$saAppPoolName = "SharePoint Web Services Default"
$saAppPoolUserName = "splive360\svcspservices"
$waAppPoolName = "SharePoint Web Content Default"
$waAppPoolUserName = "splive360\svcspcontent"

# Service Apps
Write-Host "Please supply the password for the $saAppPoolUserName Account..."
$appPoolCred = Get-Credential $saAppPoolUserName
$saAppPoolAccount = New-SPManagedAccount -Credential $appPoolCred
$saAppPool = New-SPServiceApplicationPool -Name $saAppPoolName -Account $saAppPoolAccount
# Web app
Write-Host "Please supply the password for the $waAppPoolUserName Account..."
$appPoolCred = Get-Credential $waAppPoolUserName
$waAppPoolAccount = New-SPManagedAccount -Credential $appPoolCred