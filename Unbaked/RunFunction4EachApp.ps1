$webApps = @("https://archives.mednet.med.ubc.ca",
             "https://teams.mednet.med.ubc.ca",
             "https://committees.mednet.med.ubc.ca",
             "https://projects.mednet.med.ubc.ca",
             "https://training.mednet.med.ubc.ca",
             "https://apps.mednet.med.ubc.ca",
             "https://forms.mednet.med.ubc.ca",
             "https://playground.mednet.med.ubc.ca")
            

#$webApp = Get-SPWebApplication https://archives.mednet.med.ubc.ca
#$webApp = Get-SPWebApplication https://teams.mednet.med.ubc.ca
#$webApp = Get-SPWebApplication https://committees.mednet.med.ubc.ca
#$webApp = Get-SPWebApplication https://projects.mednet.med.ubc.ca
#$webApp = Get-SPWebApplication https://training.mednet.med.ubc.ca
#$webApp = Get-SPWebApplication https://apps.mednet.med.ubc.ca
#$webApp = Get-SPWebApplication https://forms.mednet.med.ubc.ca
#$webApp = Get-SPWebApplication https://playground.mednet.med.ubc.ca

foreach ($app in $webApps)
{

    $webApp = Get-SPWebApplication $app

    foreach ($site in $webApp.sites)
    {
        C:\Deployment\Scripts\Lucas\UploadMasterPages.ps1 $site.Url
    }
}