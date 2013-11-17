$replicationPermissionName = "Replicating Directory Changes"

# set default user identity
# change CYBERTRON\spups to whatever you want the account to be
$userIdentity = Read-Host -Prompt "Enter Sync Account Name. Press Enter for splive360\svcspups"
If ($userIdentity -eq "") {
    $userIdentity = 'splive360\svcspups'
}

function Check-ADUserPermission(
    [System.DirectoryServices.DirectoryEntry]$entry, 
    [string]$user, 
    [string]$permission)
{
    $dse = [ADSI]"LDAP://Rootdse"
    $ext = [ADSI]("LDAP://CN=Extended-Rights," + $dse.ConfigurationNamingContext)

    $right = $ext.psbase.Children | 
        ? { $_.DisplayName -eq $permission }

    if($right -ne $null)
    {
        $perms = $entry.psbase.ObjectSecurity.Access |
            ? { $_.IdentityReference -eq $user } |
            ? { $_.ObjectType -eq [GUID]$right.RightsGuid.Value }

        return ($perms -ne $null)
    }
    else
    {
        Write-Warning "Permission '$permission' not found."
        return $false
    }
}

# create the permissions

$RootDSE = [ADSI]"LDAP://RootDSE"
$DefaultNamingContext = $RootDse.defaultNamingContext
$ConfigurationNamingContext = $RootDse.configurationNamingContext
$UserPrincipal = New-Object Security.Principal.NTAccount("$userIdentity")

DSACLS "$DefaultNamingContext" /G "$($UserPrincipal):CA;$($replicationPermissionName)"
DSACLS "$ConfigurationNamingContext" /G "$($UserPrincipal):CA;$($replicationPermissionName)"

# check the permissions

$entries = @(
    [ADSI]("LDAP://" + $RootDSE.defaultNamingContext),
    [ADSI]("LDAP://" + $RootDSE.configurationNamingContext));

Write-Host "User '$userIdentity': "
foreach($entry in $entries)
{
    $result = Check-ADUserPermission $entry $userIdentity $replicationPermissionName

    if($result)
    {
        Write-Host "`thas a '$replicationPermissionName' permission on '$($entry.distinguishedName)'" `
            -ForegroundColor Green
    }
    else
    {
        Write-Host "`thas no a '$replicationPermissionName' permission on '$($entry.distinguishedName)'" `
            -ForegroundColor Red
    }
}