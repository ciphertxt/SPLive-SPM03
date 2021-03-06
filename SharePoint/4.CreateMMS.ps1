# App Pools
$saAppPoolName = "SharePoint Web Services Default"
$saAppPoolUserName = "splive360\svcspservices"

# MMS specifics
$mmsServiceName = "Managed Metadata Service"
$mmsDBName = "SP2013_Auto_SA_MMS"
$hubUrl = "http://intranet.splive360.local/hub"

# Grab the Appplication Pool for Service Application Endpoint
$saAppPool = Get-SPServiceApplicationPool $saAppPoolName -ErrorAction SilentlyContinue -ErrorVariable err

if ($saAppPool -eq $null) {
    # Create Managed Account and Application Pool for Services

    # Service Apps Generic Pool
    $saAppPoolAccount = Get-SPManagedAccount -Identity $saAppPoolUserName -ErrorAction SilentlyContinue -ErrorVariable err
    if ($saAppPoolAccount -eq $null) {
        Write-Host "Please supply the password for the $saAppPoolUserName Account..."
        $appPoolCred = Get-Credential $saAppPoolUserName
        $saAppPoolAccount = New-SPManagedAccount -Credential $appPoolCred
    }

    $saAppPool = Get-SPServiceApplicationPool $saAppPoolName -ErrorAction SilentlyContinue -ErrorVariable err
    if ($saAppPool -eq $null) {
        $saAppPool = New-SPServiceApplicationPool -Name $saAppPoolName -Account $saAppPoolAccount
    }
}

Write-Host "Creating $mmsServiceName..."
$mms = New-SPMetadataServiceApplication -ApplicationPool $saAppPoolName -Name $mmsServiceName -DatabaseName $mmsDBName -HubUri $hubUrl -SyndicationErrorReportEnabled -Confirm:$false

# The proxy will error, as we're trying to set the HubUri and we haven't given
# any account explicit access to the Service App...
Write-Host "Create $mmsServiceName Proxy..."
$mmsProxy = New-SPMetadataServiceApplicationProxy -Name "$mmsServiceName Connection" -ServiceApplication $mmsServiceName -DefaultProxyGroup -ContentTypePushdownEnabled -ContentTypeSyndicationEnabled -DefaultKeywordTaxonomy -DefaultSiteCollectionTaxonomy -Confirm:$false -ErrorAction SilentlyContinue -ErrorVariable err

$proxy = Get-SPMetadataServiceApplicationProxy "$mmsServiceName Connection" -ErrorAction SilentlyContinue
if ($proxy -ne $null) {
    Write-Host "Enabling hub syndication from $hubUrl..."
    $proxy.Properties["IsNPContentTypeSyndicationEnabled"] = $true
    $proxy.Update()
}

Write-Host "Starting Managed Metadata Web Service Instance..."
Get-SPServiceInstance | where-object {$_.TypeName -eq "Managed Metadata Web Service"} | Start-SPServiceInstance 

#restart IIS so the proxy properties render through
iisreset /noforce