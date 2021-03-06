function InitSPEnv
{

    ## Load SharePoint Snapin
    try
    {
         Get-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction Stop
         Write-Host "SharePoint Snapin already loaded. Continuing..."
     }
    catch
    {
        Write-Host "Loading SharePoint Snapin"
        Add-PSSnapin Microsoft.SharePoint.PowerShell
        Write-Host "SharePoint Snapin loaded. Continuing..."
     }
    
    
}

function CheckUrl
{
    param(
    [Parameter(Mandatory=$true)]
    [string] $url,
    [int] $flag
    ) #end param

    Write-Host "Checking URL: $url"
     
    Write-Host "Stage 1: breaking up the URL"
    
    $protocol = $url.Substring(0,$url.IndexOf("//")+2)
    $url = $url.Remove(0,$url.IndexOf("//")+2)
    Write-Host "Protol: $protocol"
     if ($url.Contains("/"))
    {
        $afterUrl = $url.Remove(0,$url.IndexOf("/"))
        $url = $url.Remove($url.IndexOf("/"))
        $urlParts = $afterUrl.Split('/')
         $urlParts
    }

       

       $urlDomains = $url.Split('.')
       
       foreach ($domain in $urlDomains)
       {
            $domains = $domains + $domain + "."
        }
       $domains = $domains.Remove($domains.LastIndexOf('.'))
       
       try
       {
            
       }
       catch
       {
       
       
       }
       
       switch($flag)
       {
            0 
            {
            Get-SPWebApplication ($protocol + $domains)
            }
            
            1
            {
            
            }
             
            default 
            {
            "Not exist"
            }
       
       }

}

Function Is-SPWeb
{
param(
[Parameter(Mandatory=$true)]
[string] $url
 )

$isWeb = $false

try
{
$web = Get-SPWeb $url -ErrorAction stop
$isWeb = $true
}
catch
{
$isWeb = $false;
}

return $isWeb
}

Function Move-SPWeb
{
param(
[Parameter(Mandatory=$true)]
 [string] $source,
[Parameter(Mandatory=$true)]
[string] $destination
)

while(-not(Is-SPWeb $source))
{

   $source = Read-Host "$source is not a valid web, please re-enter the url"
    
}

$web = Get-SPWeb $source

if(-not(Is-SPWeb $destination))
{

   $newWeb = New-SPWeb -Url $destination -Template ($web.WebTemplate + "#" + $web.Configuration) -Name $web
    
}
else
{
    $newWeb = Get-SPWeb -Identity $destination
    Write-Host "Destination exists at: $newWeb"
}
 

$movepath = ("C:\" + "WebMoves" + "\")
 
Write-Host $movepath

 


if(!(Test-Path -path $movepath))
{
    "Does not exist"
    New-Item $movepath -type directory
    "now it exists"
}
else
{
    "exists"
 }

Write-Host ($movepath + $web + ".cmp")
Write-Host $web.WebTemplateID
Export-SPWeb -Identity $source -IncludeVersions All -Path ($movepath + $web + ".cmp")
Import-SPWeb -Identity $destination -Path ($movepath + $web + ".cmp")
 
}

function Set-ProfileImage
{
param(
[Parameter(Mandatory=$true)]
 [string] $username,
[Parameter(Mandatory=$true)]
 [string] $imgUrl
)
    #testing variables
    $username = "lcawkell_admin"
    $imgUrl = "https://my.mednet.med.ubc.ca/personal/lcawkell/Personal%20Documents/photo.JPG"

    #Set up default variables
 
    #My Site URL
    $mySiteUrl = "https://my.mednet.med.ubc.ca/personal/lcawkell_admin"
 
 
    #The new picture URL value
    $newURLValue = $imgUrl
      
    #The internal name for PictureURL
    $upPictureURLAttribute = "PictureURL"
     
    #Get site objects and connect to User Profile Manager service
    $site = Get-SPSite $mySiteUrl
    $context = Get-SPServiceContext $site
    $profileManager = New-Object Microsoft.Office.Server.UserProfiles.UserProfileManager($context) 

     
    #The user who's profile we want to change
    $userProfile = $profileManager.GetUserProfile($username)
      
    write-host "Before: " $userProfile[$upPictureURLAttribute] " | After: " $newURLValue
        
    #Get user profile and change the value - uncomment the lines below to commit the changes
    $userProfile[$upPictureURLAttribute].Value = $newURLValue
    $userProfile.Commit()

}