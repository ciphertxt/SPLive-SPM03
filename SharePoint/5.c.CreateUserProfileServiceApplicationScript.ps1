Add-PSSnapin Microsoft.SharePoint.PowerShell 

Write-Host 
Write-Host "This script running under the identity of $env:USERNAME"
Write-Host 

Write-Host "Checking to see if User Profile Service Application has already been created" 

$serviceApplicationName = "User Profile Service Application"
$serviceAppPoolName = "SharePoint Web Services Default"
$sqlServer = "SPSQL"
$profileDBName = "SP2013_Auto_SA_UPS_UserProfile"
$socialDBName = "SP2013_Auto_SA_UPS_Social"
$profileSyncDBName = "SP2013_Auto_SA_UPS_Sync"
$mySiteHostLocation = "http://my.splive360.local"
$mySiteManagedPath = "personal"


$serviceApplication = Get-SPServiceApplication | where {$_.Name -eq $serviceApplicationName}
if($serviceApplication -eq $null) {
  Write-Host "Creating the User Profile Service Application..."
  $serviceApplication = New-SPProfileServiceApplication `
                            -Name $serviceApplicationName `
                            -ApplicationPool $serviceAppPoolName `
                            -ProfileDBName $profileDBName `
                            -ProfileDBServer $sqlServer `
                            -SocialDBName $socialDBName `
                            -SocialDBServer $sqlServer `
                            -ProfileSyncDBName $profileSyncDBName `
                            -ProfileSyncDBServer $sqlServer `
                            -MySiteHostLocation $mySiteHostLocation `
                            -MySiteManagedPath $mySiteManagedPath `
                            -SiteNamingConflictResolution None
    
  $serviceApplicationProxyName = "User Profile Service Application"
  Write-Host "Creating the User Profile Service Proxy..."
  $serviceApplicationProxy = New-SPProfileServiceApplicationProxy `
                                 -Name $serviceApplicationProxyName `
                                 -ServiceApplication $serviceApplication `
                                 -DefaultProxyGroup 
  
  Write-Host "User Profile Service Application and Proxy have been created by the SP_Farm account"
  Write-Host 
}


# Check to ensure it worked 
Get-SPServiceApplication | ? {$_.TypeName -eq "User Profile Service Application"} 

Write-Host 
Write-Host "This script will end and this window will lose in 5 seconds"
Write-Host 

Start-Sleep -Seconds 5