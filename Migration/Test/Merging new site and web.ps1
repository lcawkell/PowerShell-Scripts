function New-SPWebFromXml
{
    Param(
    [System.Xml.XMLElement]$parentElement
    )

    $url = ""

    if([string]::IsNullOrEmpty(($url = $parentElement.destination)))
    {
        $url = $parentElement.url
    }
    
    if($parentElement.LocalName -eq "Site")
    {
        Write-Debug "Create a new site: $($parentElement.Title)"
        $site = New-SPSite -Name $parentElement.title -Url $url -Template $xmlSite.template -Description $parentElement.description -OwnerAlias $parentElement.ownerAlias -OwnerEmail $parentElement.ownerEmail -CompatibilityLevel 15

        $web = $site.RootWeb

        Sync-SPBrandingFiles -inputDirectory $parentElement.OwnerDocument.sitestructure.input -site $site

        $web.CustomMasterUrl = "$($web.ServerRelativeUrl)/_catalogs/masterpage/MedNetPublishing.master"
        $web.MasterUrl = "$($web.ServerRelativeUrl)/_catalogs/masterpage/MedNetPublishing.master"
        $web.Update()

    }elseif($parentElement.LocalName -eq "Web")
    {
        Write-Debug "Creating new web: $($parentElement.title)"
        Write-Debug "New web url: $url"
        Write-Debug "New web template: $($parentElement.template)"
        $web = New-SPWeb -Url $url -Template $parentElement.template -Name $parentElement.title
        $web.Title = $parentElement.title
        $web.Update()
    }else
    {
        Write-Error "Something went wrong. It looks like no site or web was given"
        Write-Error "$($parentElement.LocalName)"
    }



    <#
     These two libraries are not available by default
     so these commands "ensure" they are available before 
     we try to add items to them.
    #>
    $web.Lists.EnsureSiteAssetsLibrary()
    $web.Lists.EnsureSitePagesLibrary()

    $publishingWeb = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($web)

    $pubWebNavigation = $publishingWeb.Navigation
        
    $pubWebNavigation.InheritGlobal = [System.Convert]::ToBoolean($parentElement.navigation.inheritglobal)
    $pubWebNavigation.InheritCurrent = [System.Convert]::ToBoolean($parentElement.navigation.inheritcurrent)
    $pubWebNavigation.GlobalIncludeSubSites = [System.Convert]::ToBoolean($parentElement.navigation.globalincludesubsites)
    $pubWebNavigation.GlobalIncludePages = [System.Convert]::ToBoolean($parentElement.navigation.globalincludepages)
    $pubWebNavigation.ShowSiblings = [System.Convert]::ToBoolean($parentElement.navigation.currentshowsiblings)
    $pubWebNavigation.CurrentIncludeSubSites = [System.Convert]::ToBoolean($parentElement.navigation.currentincludesubsites)
    $pubWebNavigation.CurrentIncludePages = [System.Convert]::ToBoolean($parentElement.navigation.currentincludepages)

    $pubWebNavigationNodes = $pubWebNavigation.CurrentNavigationNodes
    $CreateSPNavigationNode = [Microsoft.SharePoint.Publishing.Navigation.SPNavigationSiteMapNode]::CreateSPNavigationNode

    foreach($node in $parentElement.navigation.node)
    {
        $headingNode = $CreateSPNavigationNode.Invoke($node.title, $node.url, [Microsoft.SharePoint.Publishing.NodeTypes]::Page, $pubWebNavigationNodes)
    }


    $publishingWeb.Update()

    foreach($xmlLibrary in $parentElement.library)
    {
        $libraryTitle = $xmlLibrary.Title

        try
        {
            $library = $web.Lists[$libraryTitle]
            Add-SPFilesFromXml -xmlElement $xmlLibrary.folder -folder $library.RootFolder
        }catch
        {
            Write-Debug "Library does not exist. Creating a new library"
        }
    }

    New-SPLibrariesFromXml -web $web -parentElement $parentElement


    foreach($xmlWeb in $parentElement.web)
    {
        New-SPWebFromXml -parentElement $xmlWeb
    }

}