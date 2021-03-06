#Make backup copy of the Hosts file with today's date
$hostsfile = 'C:\Windows\System32\drivers\etc\hosts'
$date = Get-Date -UFormat "%y%m%d%H%M%S"
$filecopy = $hostsfile + '.' + $date + '.copy'
Copy-Item $hostsfile -Destination $filecopy
 
$hosts = @( "intranet.splive360.local", "intranet", "my.splive360.local", "my", "ca.splive360.local", "ca" )
  
# Get the contents of the Hosts file
$file = Get-Content $hostsfile
#$file = $file | Out-String
 
# write the AAMs to the hosts file, unless they already exist.
foreach ($hostEntry in $hosts) {
    Write-Host "Evaluating entry for $hostEntry..."
    $entryExists = $false
    if ($file -contains "127.0.0.1 `t $hostEntry ") {
        Write-Host "Entry for $hostEntry already exists. Skipping..."
        $entryExists = $true
    }

    if (!$entryExists) {
        Write-host "Adding entry for $hostEntry" 
        add-content -path $hostsfile -value "127.0.0.1 `t $hostEntry "
    }
}