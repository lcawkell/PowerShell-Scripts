$webs = 
"https://training.fomiuat.med.ubc.ca/glossary/",
"https://training.fomiuat.med.ubc.ca/Basics/",
"https://training.fomiuat.med.ubc.ca/governance/",
"https://training.fomiuat.med.ubc.ca/publishedcontent/",
"https://training.fomiuat.med.ubc.ca/teamsites/"

function RemoveSPWebRecursively(
    [Microsoft.SharePoint.SPWeb] $web)
{
    Write-Debug "Removing site ($($web.Url))..."
    
    $subwebs = $web.GetSubwebsForCurrentUser()
    
    foreach($subweb in $subwebs)
    {
        RemoveSPWebRecursively($subweb)
        $subweb.Dispose()
    }
    
    $DebugPreference = "SilentlyContinue"
    Remove-SPWeb $web -Confirm:$false
    $DebugPreference = "Continue"
}

foreach ($web in $webs)
{
    $DebugPreference = "SilentlyContinue"
    $web = Get-SPWeb $web
   # $DebugPreference = "Continue"

    If ($web -ne $null)
    {
        RemoveSPWebRecursively $web
        $web.Dispose()
    }
}