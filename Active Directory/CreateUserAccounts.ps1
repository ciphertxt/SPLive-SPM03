#Import Active Directory Module
Import-module activedirectory

#Declare any Variables
$dirpath = $pwd.path
$counter = 0

# Set the OU information and create the OU if it doesn't exist
$OU= Read-Host -Prompt "Enter OU name you want. Press Enter for Test Users"
If ($OU -eq "") {$OU = 'Test Users'}
$FQDN = (Get-ADDomain).DistinguishedName
# Get domain DNS suffix
$dnsroot = '@' + (Get-ADDomain).DNSRoot

If ([adsi]::Exists("LDAP://OU=$OU, $FQDN") -eq $True) {
	write-host "The OU already exists" -ForegroundColor DarkGreen -BackgroundColor Gray
} else {
	dsadd ou "ou=$OU,$FQDN"
}

$OU_specified = "ou=$OU,$FQDN"

# set default password
# change pass@word1 to whatever you want the account passwords to be
$userpassword = Read-Host -Prompt "Enter Farm Account Password. Press Enter for Devise!!!"
If ($userpassword -eq "") {
	$userpassword = 'Devise!!!'
}

$password = (ConvertTo-SecureString $userpassword -AsPlainText -Force)

# import CSV File
# specify the file location
$csvfile = "$dirpath\ADUsers.csv"
$userfile = Read-Host -Prompt "Enter the location of the CSV file containing the users you want to import. Press Enter for $csvfile"
If ($userfile -eq "") {
	$userfile = $csvfile
}

$ImportFile = Import-csv $userfile
$TotalImports = $importFile.Count

#Create Users
$ImportFile | foreach {
	$counter++
	$progress = [int]($counter / $totalImports * 100)
	Write-Progress -Activity "Provisioning User Accounts" -status "Provisioning account $counter of $TotalImports" -perc $progress
	if ($_.Manager -eq "") {
		New-ADUser -SamAccountName $_.SamAccountName -Name $_.Name -Surname $_.Sn -GivenName $_.GivenName -Path $OU_specified -AccountPassword $password -Enabled $true -title $_.title -officePhone $_.officePhone -department $_.department -EmailAddress ($_.SamAccountName + $dnsroot) -UserPrincipalName ($_.SamAccountName + $dnsroot) -ChangePasswordAtLogon $false -PasswordNeverExpires  $true
	} else {
		$manager = $_.Manager + "," + $OU_specified
    	New-ADUser -SamAccountName $_.SamAccountName -Name $_.Name -Surname $_.Sn -GivenName $_.GivenName -Path $OU_specified -AccountPassword $password -Enabled $true -title $_.title -officePhone $_.officePhone -department $_.department -manager $manager -EmailAddress ($_.SamAccountName + $dnsroot) -UserPrincipalName ($_.SamAccountName + $dnsroot) -ChangePasswordAtLogon $false -PasswordNeverExpires  $true
	}

	If (test-path -path "$dirpath\userimages\$($_.name).jpg") {
		$photo = [System.IO.File]::ReadAllBytes("$dirpath\userImages\$($_.name).jpg")
		Set-ADUSER $_.samAccountName -Replace @{thumbnailPhoto=$photo}
	}
}
