function Delete-SiteCollections
{
[CmdletBinding()]
Param
(
[Microsoft.SharePoint.SPSite]$site
)
    Write-Verbose "Starting to delete site: $site"
    foreach($web in $site.rootweb.webs)
    {
        Write-Verbose "$($site.rooweb.webs.count) subwebs exist"
        Delete-SPWebRecursive -web $web
    }
    Write-Verbose "Deleting site: $site"
    Remove-SPSite -Identity $site -Confirm:$false
}

function Delete-SPWebRecursive
{
[CmdletBinding()]
Param
(
[Microsoft.SharePoint.SPWeb]$web
)
    Write-Verbose "Starting to delete web: $web"
    foreach($subweb in $web.webs)
    {
        Write-Verbose "$($site.rooweb.webs.count) subwebs exist"
        Delete-SPWebRecursive -web $subweb
    }
    Write-Verbose "Deleting web: $web"
    Remove-SPWeb -Identity $web -Confirm:$false

}

for($i=60;$i -lt 100;$i++)
{
    try
    {
        $site = Get-SPSite https://test.mednet.med.ubc.ca/sites/intranet$i -ErrorAction Stop
        Delete-SiteCollections $site -Verbose
    }
    catch
    {
        Write-Debug "Site does not exist"
    }
}


