$appDomain = "contosoapps.com"
$appDomainPrefix = "app"
$subSettingsSvc = Get-SPServiceInstance | ? { $_.TypeName -eq "Microsoft SharePoint Foundation Subscription Settings Service" }
$appMgmtSvc = Get-SPServiceInstance | ? { $_.TypeName -eq "App Management Service" } 

Start-SPServiceInstance $subSettingsSvc
Start-SPServiceInstance $appMgmtSvc

# Creates the Subscription Settings service application, using the variable to associate it with the application pool that was created earlier.
# Stores the new service application as a variable for later use.
$svcAppPool = Get-SPServiceApplicationPool "SharePoint Web Services Default"
$appSubSvc = New-SPSubscriptionSettingsServiceApplication -ApplicationPool $svcAppPool -Name "Subscription Settings Service Application" -DatabaseName "Contoso_SA_SubscriptionSettings"

# Creates a proxy for the Subscription Settings service application.
$proxySubSvc = New-SPSubscriptionSettingsServiceApplicationProxy -ServiceApplication $appSubSvc

# Creates the Application Management service application, using the variable to associate it with the application pool that was created earlier.
# Stores the new service application as a variable for later use.
$appAppSvc = New-SPAppManagementServiceApplication -ApplicationPool $svcAppPool -Name "App Management Service Application" -DatabaseName "ESDEVWFE01_SA_AppManagement"

# Creates a proxy for the Application Management service application.
$proxyAppSvc = New-SPAppManagementServiceApplicationProxy -ServiceApplication $appAppSvc

# Set the base domain
Set-SPAppDomain $appDomain
# Set the app prefix
Set-SPAppSiteSubscriptionName -Name $appDomainPrefix -Confirm:$false
