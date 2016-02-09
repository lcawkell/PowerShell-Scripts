function CopySite
{
Param(
[Parameter(Mandatory=$true)]
[string]$originSiteUrl,
[Parameter(Mandatory=$true)]
[string]$destinationSiteUrl
)

    $originSite = $null
    $destinationSite = $null
    $useExisting = $null;
    $template = $null;
    $originSite = Get-SPSite https://test.mednet.med.ubc.ca

    if(($originSite = Get-SPSite $originSiteUrl -ErrorAction SilentlyContinue) -ne $null)
    {
       $template = "$($originSite.RootWeb.WebTemplate)#$($originSite.RootWeb.Configuration)"
    }

    if(($destinationSite = Get-SPSite $destinationSiteUrl -ErrorAction SilentlyContinue) -ne $null)
    {
        while(($useExisting -ne "y") -and ($useExisting -ne "n"))
        {
            if($useExisting -ne $null)
            {
                Write-Host "That selection was invalid. Please enter y or no" -ForegroundColor Red
            }
            $useExisting = Read-Host "Destination site already exists. Use that? (y/n)"
        }

        
        if($useExisting -eq "y")
        {
            Write-Host "Using existing site..."
        }
        else
        {
            Write-Host "Will not overwrite the site. Exiting."
            break;
        }

    }
    else
    {
        Write-Host "Destination site does not exist. Creating..."
        
        try
        {
            $destinationSite = New-SPSite -Url $destinationSiteUrl -Template $template -Name $originSite.RootWeb.Name -Description $originSite.RootWeb.Description -OwnerEmail $originSite.Owner.Email -OwnerAlias $originSite.Owner -CompatibilityLevel 15 -ErrorAction Stop
        }catch
        {
            $currentUser = "fom\"+[Environment]::UserName
            Write-Host "Original User, $($originSite.Owner) not found. Creating site as current user: $currentUser"
            $destinationSite = New-SPSite -Url $destinationSiteUrl -Template $template -Name $originSite.RootWeb.Name -Description $originSite.RootWeb.Description -OwnerAlias $currentUser -CompatibilityLevel 15
        }

        Write-Host "Created site $($desinationSite.RootWeb.Name)"
    }


}

function Copy-Web
{
Param(
[Parameter(Mandatory=$true)]
[string]$originUrl,
[Parameter(Mandatory=$true)]
[string]$destinationUrl,
[string]$template,
[string]$name
)

#
# Set Defaults
#
$template = if($template -eq $null) {"BLANKINTERNET#0"} else {$template}
$name = if($name -eq $null) {"Home"} else {$name}

$newWeb = New-SPWeb -Url $destinationUrl -Template $template -Name $name

foreach($subsite in 

}