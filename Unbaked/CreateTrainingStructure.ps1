#include file
. "C:\Deployment\Scripts\Miguel\includeFunctions.ps1"
. "C:\Deployment\Scripts\Miguel\GlobalVariables.ps1"

# set log file
SetLogFile

#load the SharePoint snapin
cls
loadSnapins
#load assemblies
[Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")


[xml]$siteStructure = Get-Content "C:\XML\ResearchSiteStructure.xml"

$structureUrl = $siteStructure.structure.root
$sites = $siteStructure.structure.sites.site


function CreateWebs($baseUrl, $webs, [int]$progressid, $level) 
{ 
    $webcount = $webs.ChildNodes.Count 
    $counter = 0 
    foreach ($web in $webs.web) 
    { 
        Write-Progress -ID $progressid -Activity "Creating webs" -status "Creating $($web.Name)" -percentComplete ($counter / $webcount*100) 
        $counter = $counter + 1
        $sidenav = $false
        $topnav = $false
        if($web.sidenav -eq "true")
        {
            $sidenav = $true
        }
        if($web.topnav -eq "true")
        {
            $topnav = $true
        }
       # DELETE $newSite = Get-SPWeb https://training.fomiuat.med.ubc.ca/basics
        Write-Host "Creating $($web.name) $($baseUrl)$($web.url)... TopNav:$($topnav) SideNav:$($sidenav)" 
        $newSite = New-SPWeb -Url "$($baseUrl)$($web.url)" -AddToQuickLaunch:$false -AddToTopNav:$topnav -Confirm:$false -Name "$($web.name)" -Template "BLANKINTERNET#0" -UseParentTopNav:$true
       # $newSite = Get-SPWeb https://training.fomiuat.med.ubc.ca/basics
        $page = $newSite.GetFile($newSite.Url + "/Pages/default.aspx")
        $page.CheckOut("Online", $null)
        $spWpManager = $newSite.GetLimitedWebPartManager($page.Url, [System.Web.UI.WebControls.WebParts.PersonalizationScope]::Shared)
        $spWPManager.DeleteWebPart($spWPManager.WebParts[0])
        $page.Properties["PublishingPageLayout"] = "/_catalogs/masterpage/ubcfom_inner_1col.aspx, ubcfom_inner_1col"
        $page.Update()
        $page.CheckIn("Checked in by PowerShell", [Microsoft.SharePoint.SPCheckinType]::MajorCheckIn)
        $page.Publish("Published by PowerShell")
        $page.Approve("Approved by PowerShell")
        ActivateFeature $brandingFeatureActivationFeatureID "$($baseUrl)$($web.url)" "Branding Activation Feature" $false $false
        ActivateFeature "94c94ca6-b32f-4da9-a9e3-1f3d343d7ecb" "$($baseUrl)$($web.url)" "Publishing Web" $false $false
        
        Start-Sleep -s 2
        
        CleanSite $newSite $level
        
        if ($web.ChildNodes.Count -gt 0) 
        { 
            CreateWebs "$($baseUrl)$($web.Url)" $web ($progressid +1) ($level+1)
        } 
        Write-Progress -ID $progressid -Activity "Creating sites" -status "Creating $($site.Name)" -Completed 
    } 
} 

function CleanSite($web, $level)
{
    #$web = Get-SPWeb https://training.fomiuat.med.ubc.ca/basics
    #$level = 2
    $pubWeb = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($web)
    $qlNav = $pubWeb.Navigation.CurrentNavigationNodes
    if($level -eq 1)
    {
        Write-Host "Level 1 $($web.Name)"
        $pubWeb.Navigation.InheritCurrent = $false
        $pubWeb.Navigation.ShowSiblings = $false
        $pubWeb.Navigation.CurrentIncludeSubSites = $true
        $pubWeb.Navigation.CurrentIncludePages = $false
        $pubWeb.Navigation.OrderingMethod = "Automatic"
        $pubWeb.Navigation.AutomaticSortingMethod = "CreatedDate"
        $pubWeb.Update()
    }
        if($level -eq 2)
    {
        Write-Host "Level 2 $($web.Name)"
        $pubWeb.Navigation.InheritCurrent = $false
        $pubWeb.Navigation.ShowSiblings = $true
        $pubWeb.Navigation.CurrentIncludeSubSites = $true
        $pubWeb.Navigation.CurrentIncludePages = $false
        $pubWeb.Navigation.OrderingMethod = "Automatic"
        $pubWeb.Navigation.AutomaticSortingMethod = "CreatedDate"
        $pubWeb.Update()
    }
        if($level -eq 3)
    {
        Write-Host "Level 3 $($web.Name)"
        $pubWeb.Navigation.InheritCurrent = $true
        $pubWeb.Navigation.ShowSiblings = $true
        $pubWeb.Navigation.CurrentIncludeSubSites = $true
        $pubWeb.Navigation.CurrentIncludePages = $false
        $pubWeb.Navigation.OrderingMethod = "Automatic"
        $pubWeb.Navigation.AutomaticSortingMethod = "CreatedDate"
        $pubWeb.Update()
    }
    $qlHeading = $qlNav | where { $_.Title -eq "Sites" }
    if($qlHeading -ne $null)
    {
        $qlHeading.Delete()
    }
    $qlNav = $pubWeb.Navigation.CurrentNavigationNodes
    $qlHeading = $qlNav | where { $_.Title -eq "Libraries" }
    if($qlHeading -ne $null)
    {
        $qlHeading.Delete()
    }
    $qlNav = $pubWeb.Navigation.CurrentNavigationNodes
    $qlHeading = $qlNav | where { $_.Title -eq "Lists" }
    if($qlHeading -ne $null)
    {
        $qlHeading.Delete()
    }
    $qlNav = $pubWeb.Navigation.CurrentNavigationNodes
    $qlHeading = $qlNav | where { $_.Title -eq "Discussions" }
    if($qlHeading -ne $null)
    {
        $qlHeading.Delete()
    }
    
    $pages = $pubWeb.PagesList
    
    foreach($item in $pages.Items)
             {
                 $pubPage = [Microsoft.SharePoint.Publishing.PublishingPage]::GetPublishingPage($item)
                 
                     $pubPage.CheckOut()
                     $pubPage.Title = $web.Title
                     $pubPage.Update();
                     $pubPage.CheckIn("Check in Comment")
                     $pageFile = $pubPage.ListItem.File;
                     $pageFile.Publish("publishComment");
                     $pageFile.Approve("checkInComment");                 
             }
 


}


foreach($site in $sites)
{

    ActivateFeature "f6924d36-2fa8-4f0b-b16d-06b7250180fa" "$($structureUrl)$($site.url)" "Publishing Infrastructure Feature" $false $false
    ActivateFeature $UBCFOMBrandingAssetsFeatureGuid "$($structureUrl)$($site.url)" "Branding Assets Feature" $false $false
    CreateWebs $structureUrl $site 1 2
    
  
}
