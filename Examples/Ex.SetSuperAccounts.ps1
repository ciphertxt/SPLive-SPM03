$superUser = "splive360\svcspsuperuser"
$superReader = "splive360\svcspsuperreader"

foreach ($wa in Get-SPWebApplication) {
    # Set Super User
    $policy = $wa.Policies.Add($superUser, $superUser)
    $userpolicy = $wa.PolicyRoles.GetSpecialRole("FullControl")
    $policy.PolicyRoleBindings.Add($userpolicy)
    $wa.Properties["portalsuperuseraccount"] = $superUser
    $wa.Update()
     
    # Set Super User
    $policy = $wa.Policies.Add($superReader, $superReader)
    $userpolicy = $wa.PolicyRoles.GetSpecialRole("FullRead")
    $policy.PolicyRoleBindings.Add($userpolicy)
    $wa.Properties["portalsuperreaderaccount"] = $superReader
    $wa.Update()
}