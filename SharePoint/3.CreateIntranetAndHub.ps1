# Create Content Managed Accounts and Application Pools
$waAppPoolName = "SharePoint Web Content Default"
$waAppPoolUserName = "splive360\svcspcontent"
$intranetHeader = "intranet.splive360.local"
$intranetFullURL = "http://" + $intranetHeader
$intranetDBName = "SP2013_Auto_Content_Intranet"
$intranetSCTitle = "SPLive Intranet"
$hubSCTitle = "Content Type Hub"
$farmAccount = "splive360\svcspfarm"

# Web apps

# Grab the Appplication Pool for Service Application Endpoint
$waAppPool = Get-SPServiceApplicationPool $waAppPoolName -ErrorAction SilentlyContinue -ErrorVariable err

if ($waAppPool -eq $null) {
    # Create Managed Account and Application Pool for Services

    # Service Apps Generic Pool
    $waAppPoolAccount = Get-SPManagedAccount -Identity $waAppPoolUserName -ErrorAction SilentlyContinue -ErrorVariable err
    if ($waAppPoolAccount -eq $null) {
        Write-Host "Please supply the password for the $saAppPoolUserName Account..."
        $appPoolCred = Get-Credential $waAppPoolUserName
        $waAppPoolAccount = New-SPManagedAccount -Credential $appPoolCred
    }

    $waAppPool = Get-SPServiceApplicationPool $saAppPoolName -ErrorAction SilentlyContinue -ErrorVariable err
    if ($waAppPool -eq $null) {
        $waAppPool = New-SPServiceApplicationPool -Name $saAppPoolName -Account $saAppPoolAccount
    }
}

# Create the Inranet Web app. Creation of the web app will create our application pool.
Write-Host "Creating Web Application..."
$ap = New-SPAuthenticationProvider -UseWindowsIntegratedAuthentication -DisableKerberos 
New-SPWebApplication -Name $intranetHeader `
                     -Port 80 `
                     -HostHeader $intranetHeader `
                     -ApplicationPool $waAppPoolName `
                     -ApplicationPoolAccount $waAppPoolAccount `
                     -AuthenticationMethod "NTLM" `
                     -AuthenticationProvider $ap `
                     -DatabaseName $intranetDBName `
                     -Url $intranetFullURL `
                     -Confirm:$false | out-null

# Create the intranet site collection in the root
Write-Host "Creating Intranet Root Site Collection at $intranetFullURL..."
New-SPSite -Name $intranetSCTitle -Url $intranetFullURL -OwnerAlias $farmAccount -Template "STS#0" -ContentDatabase $intranetDBName -Confirm:$false | out-null

# Create the /personal managed path
Write-Host "Setting Managed Path for /hub..."
New-SPManagedPath -RelativeURL "hub" -WebApplication $intranetFullURL -Explicit | out-null

# Create the Content Hub site collection in /hub
Write-Host "Creating Hub Site Collection at $intranetFullURL/hub..."
$hubUrl = $intranetFullURL + "/hub"
New-SPSite -Name $hubSCTitle -Url $hubUrl -OwnerAlias $farmAccount -Template "STS#0" -ContentDatabase $intranetDBName -Confirm:$false | out-null

# Activate the Hub Feature
Write-Host "Activating Content Type Hub..."
$feature = get-spfeature -site $hubUrl | where-object{$_.displayname -eq "ContentTypeHub"}
if ($feature -eq $null) {
    $site = Get-SPSite $hubUrl
    Enable-SPFeature -Identity "ContentTypeHub" -Url $site.Url
}