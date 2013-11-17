$currentScriptPath = $MyInvocation.MyCommand.Path
$scriptFolder = Split-Path $currentScriptPath
$targetScriptPath = Join-Path $scriptFolder "\5.c.CreateUserProfileServiceApplicationScript.ps1"

Add-PSSnapin Microsoft.SharePoint.PowerShell 

function Create-UserProfileServiceApplication {

    $service = Get-SPServiceInstance | where {$_.TypeName -eq "User Profile Service"}
    if ($service.Status -ne "Online") {
        Write-Host "Starting User Profile Service instance" -NoNewline
        $service | Start-SPServiceInstance | Out-Null

        # ensure the service is online before attempting to add a svc app.
        while ($true) {
            Start-Sleep 2
            Write-Host "." -NoNewLine
            $svc = Get-SPServiceInstance | where {$_.TypeName -eq "User Profile Service"}
            if ($svc.Status -eq "Online") { break }
        }
        Write-Host
    }

    # call to script which can run as splive360\svcspfarm with administrator privledges
    # this will require you to chose OK when prompted about elevation
    Write-Host "Executing script $targetScriptPath using credentials of svcspfarm"

    # Get the Farm Account Creds 
    $servicesAccountName = "splive360\svcspfarm"
    $servicesAccountPassword = "Devise!!!"
    $servicesAccountecureStringPassword = ConvertTo-SecureString -String $servicesAccountPassword -AsPlainText -Force
    $farmAccountCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $servicesAccountName, $servicesAccountecureStringPassword 

    # Create a new process with UAC elevation 
    Start-Process $PSHOME\powershell.exe `
                  -Credential $farmAccountCredentials `
                  -ArgumentList "-Command Start-Process $PSHOME\powershell.exe -ArgumentList `"'$targetScriptPath'`" -Verb Runas" -Wait 

}

function Start-UserProfileSynchronizationService {

    $svc = Get-SPServiceInstance | where {$_.TypeName -eq "User Profile Synchronization Service"}
    $app = Get-SPServiceApplication -Name "User Profile Service Application"

    if ($svc.Status -ne "Online") {
        Write-Host "Starting the User Profile Service Synchronization instance (Everyone cross your toes!!!)" -NoNewline
        $svc.Status = "Provisioning"
        $svc.IsProvisioned = $false
        $svc.UserProfileApplicationGuid = $app.Id
        $svc.Update()

        $objIPProperties = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()
        $currentHostName = $objIPProperties.HostName

        $app.SetSynchronizationMachine($currentHostName, $svc.Id, "splive360\svcspfarm", "Devise!!!")
          
        $svc | Start-SPServiceInstance | Out-Null
        
        # ensure the service is online before attempting to add a svc app.
        # blocking on service start disable to reach end of script
        while ($true) {
            Start-Sleep 5
            Write-Host "." -NoNewLine
            $svc = Get-SPServiceInstance $svc.Id
            if ($svc.Status -eq "Online") { break }
        }

        Write-Host
    }
}

function Set-UPSConnectionPermission{

    $accountName = "splive360\svcspups"
 
    $claimType = "http://schemas.microsoft.com/sharepoint/2009/08/claims/userlogonname"
    $claimValue = $accountName
    $claim = New-Object Microsoft.SharePoint.Administration.Claims.SPClaim($claimType, $claimValue, "http://www.w3.org/2001/XMLSchema#string", [Microsoft.SharePoint.Administration.Claims.SPOriginalIssuers]::Format("Windows"))
    $claim.ToEncodedString()
 
    $permission = [Microsoft.SharePoint.Administration.AccessControl.SPIisWebServiceApplicationRights]"FullControl"
 
    $SPAclAccessRule = [Type]"Microsoft.SharePoint.Administration.AccessControl.SPAclAccessRule``1"
    $specificSPAclAccessRule = $SPAclAccessRule.MakeGenericType([Type]"Microsoft.SharePoint.Administration.AccessControl.SPIisWebServiceApplicationRights")
    $ctor = $SpecificSPAclAccessRule.GetConstructor(@([Type]"Microsoft.SharePoint.Administration.Claims.SPClaim",[Type]"Microsoft.SharePoint.Administration.AccessControl.SPIisWebServiceApplicationRights"))
    $accessRule = $ctor.Invoke(@([Microsoft.SharePoint.Administration.Claims.SPClaim]$claim, $permission))
 
    $ups = Get-SPServiceApplication | ? { $_.TypeName -eq 'User Profile Service Application' }
    $accessControl = $ups.GetAccessControl()
    $accessControl.AddAccessRule($accessRule)
    $ups.SetAccessControl($accessControl)
    $ups.Update()

}

Create-UserProfileServiceApplication

Start-UserProfileSynchronizationService

Set-UPSConnectionPermission