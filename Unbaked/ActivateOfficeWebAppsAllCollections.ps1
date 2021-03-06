$webAppsFeatureId = $(Get-SPFeature -limit all | where {$_.displayname -eq "OfficeWebApps"}).Id 

$webApps = "http://teams.fomiuat.med.ubc.ca/", "http://apps.fomiuat.med.ubc.ca", "http://committees.fomiuat.med.ubc.ca", "http://projects.fomiuat.med.ubc.ca", "http://training.fomiuat.med.ubc.ca"

foreach ($app in $webApps)
{
    $webApp = Get-SPWebApplication $app
    $siteCollections = Get-SPSite -WebApplication $webApp -Limit ALL
    
    foreach ($site in $siteCollections)
    {


            Enable-SPFeature $webAppsFeatureId -Url $site.url

            Start-Sleep -Seconds 1

            Write-Host Feature activated on site: $site.url

            
    }
}