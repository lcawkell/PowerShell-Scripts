
param([string]$siteUrl)

Write-Host "Starting site: $siteUrl"

#include file
. "C:\Deployment\Scripts\includeFunctions.ps1"
. "C:\Deployment\Scripts\GlobalVariables.ps1"

# set log file
SetLogFile

#load the SharePoint snapin
cls
loadSnapins

#load assemblies
[Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")


$site = Get-SPSite $siteUrl
# Get the root
Write-Host "Grabbing root site"
$web = $site.RootWeb

#Get authenticated users account
Write-Host "Grabbing Authenticated Users account"
$account = $web.EnsureUser("NT AUTHORITY\Authenticated Users")
#Give read permissions
Write-Host "Giving read permissions to $account"
$role = $web.RoleDefinitions["Read"]
$assignment = New-Object Microsoft.SharePoint.SPRoleAssignment($account)
$assignment.RoleDefinitionBindings.Add($role)
#Get Master Page Gallery
Write-Host "Getting Masterpage Gallery"
$list = $web.Lists["Master Page Gallery"]
Write-Host "Got list: " $list "... breaking Inheritance"
$list.BreakRoleInheritance($true)
$list.RoleAssignments.Add($assignment)
Write-Host "Everything looks good! Updating..."
$list.Update()
$web.Dispose()
Write-Host "DONE!"