function Set-Navigation {
    param (
        $WebUrl,
        $MenuItems
    )
     
    $site = New-Object Microsoft.SharePoint.SPSite($WebUrl)
    $web = $site.OpenWeb()
     
    # fake context
    [System.Web.HttpRequest] $request = New-Object System.Web.HttpRequest("", $web.Url, "")
    $sw = New-Object System.IO.StringWriter
    $hr = New-Object System.Web.HttpResponse($sw)
    [System.Web.HttpContext]::Current = New-Object System.Web.HttpContext($request, $hr)
    [Microsoft.SharePoint.WebControls.SPControl]::SetContextWeb([System.Web.HttpContext]::Current, $web)
     
    # initalize what has to be initialized
    $pweb = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($web)
    $dictionary = New-Object "System.Collections.Generic.Dictionary``2[[System.Int32, mscorlib, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089],[Microsoft.SharePoint.Navigation.SPNavigationNode, Microsoft.SharePoint, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c]]"
    $collection = $pweb.Navigation.CurrentNavigationNodes
     
    # get current nodes
    $globalNavSettings = New-Object System.Configuration.ProviderSettings("CurrentNavSiteMapProvider", "Microsoft.SharePoint.Publishing.Navigation.PortalSiteMapProvider, Microsoft.SharePoint.Publishing, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c")
    $globalNavSettings.Parameters["NavigationType"] = "Current"
    $globalNavSettings.Parameters["EncodeOutput"] = "true"
    [Microsoft.SharePoint.Publishing.Navigation.PortalSiteMapProvider] $globalNavSiteMapProvider = [System.Web.Configuration.ProvidersHelper]::InstantiateProvider($globalNavSettings, [type]"Microsoft.SharePoint.Publishing.Navigation.PortalSiteMapProvider")
    [Microsoft.SharePoint.Publishing.Navigation.PortalSiteMapNode] $currentNode = $($globalNavSiteMapProvider.CurrentNode)
    $children = $currentNode.GetNavigationChildren([Microsoft.SharePoint.Publishing.NodeTypes]::Default, [Microsoft.SharePoint.Publishing.NodeTypes]::Default, [Microsoft.SharePoint.Publishing.OrderingMethod]::Manual, [Microsoft.SharePoint.Publishing.AutomaticSortingMethod]::Title, $true, -1);
     
    # reorder nodes
    [Array]::Reverse($menuItems)
    $menuNodes = New-Object System.Collections.ObjectModel.Collection[Microsoft.SharePoint.Publishing.Navigation.PortalSiteMapNode]
    foreach ($node in $children) {
        $menuNodes.Add($node)
    }
     
    foreach ($menuItem in $menuItems) {
        $node = $null
        foreach ($p in $menuNodes) {
            if ($p.InternalUrl -eq $menuItem) {
                $node = $p
                break
            }
        }
         
        if ($node -ne $null) {
            [void] $menuNodes.Remove($node)
            [Void] $menuNodes.Insert(0, $node)
        }
    }
     
    foreach ($node in $menuNodes) {
        Write-Host "$($node.InternalUrl)..." -NoNewline
        $quickId = Get-QuickId $node
        if ($quickId -ne $null) {
            [string]$typeId = $null;
            if (($node.Type -eq [Microsoft.SharePoint.Publishing.NodeTypes]::Area) -or ($node.Type -eq [Microsoft.SharePoint.Publishing.NodeTypes]::Page)) {
                if ($node.PortalProvider.NavigationType -eq [Microsoft.SharePoint.Publishing.Navigation.PortalNavigationType]::Current) {
                    $typeId = [Microsoft.SharePoint.Publishing.Navigation.PortalNavigationType]::Current.ToString() + "_" + $node.Type.ToString()
                }
                else {
                    $typeId = [Microsoft.SharePoint.Publishing.Navigation.PortalNavigationType]::Global.ToString() + "_" + $node.Type.ToString()
                }
            }
            else {
                $typeId = $node.Type.ToString();
            }
 
            $id = $quickId.Split(',');
            $objId = New-Object Guid($id[0]);
            $nodeId = [System.Int32]::Parse($id[1]);
 
            $navigationNode = Get-NavigationNode $objId $nodeId $node.InternalTitle $node.InternalUrl $node.Description $node.Type $node.Target $node.Audience $collection $dictionary
            $containsNode = $false
            foreach ($mi in $menuItems) {
                if ($mi -eq $node.InternalUrl) {
                    $containsNode = $true
                    break
                }
            }
             
            if ($containsNode) {
                $pweb.Navigation.IncludeInNavigation($true, $objId)
            }
            else {
                $pweb.Navigation.ExcludeFromNavigation($true, $objId)
            }
        }
        Write-Host "DONE"
    }
 
    $pweb.Web.Update()
 
    [System.Web.HttpContext]::Current = $null
}
 
function Get-QuickId {
    param (
        [Microsoft.SharePoint.Publishing.Navigation.PortalSiteMapNode] $node
    )
     
    $quickId = $null
     
    $portalSiteMapNodeType = $node.GetType()
    $QuickId = $portalSiteMapNodeType.GetProperty("QuickId", [System.Reflection.BindingFlags] "Instance, NonPublic")
    $quickId = [string] $QuickId.GetValue($node, $null)
     
    $quickId
}
 
function Get-NavigationNode {
    param (
        [Guid] $objId,
        [int] $nodeId,
        [string] $name,
        [string] $url,
        [string] $description,
        [Microsoft.SharePoint.Publishing.NodeTypes] $nodeType,
        [string] $target,
        [string] $audience,
        [Microsoft.SharePoint.Navigation.SPNavigationNodeCollection] $collection,
        $oldDictionary
    )
     
    [Microsoft.SharePoint.Navigation.SPNavigationNode] $node = $null
    if (($objId -ne [Guid]::Empty) -and ($nodeId -ge 0)) {
        if ($oldDictionary.TryGetValue($nodeId, [ref]$node)) {
            $oldDictionary.Remove($nodeId)
            $node = [Microsoft.SharePoint.Publishing.Navigation.SPNavigationSiteMapNode]::UpdateSPNavigationNode($node.Navigation.GetNodeById($node.Id), $null, $name, $url, $description, $target, $audience, $false)
            $node.MoveToLast($collection)
        }
         
        return $node
    }
     
    $node = [Microsoft.SharePoint.Publishing.Navigation.SPNavigationSiteMapNode]::CreateSPNavigationNode($name, $url, $nodeType, $collection)
    return [Microsoft.SharePoint.Publishing.Navigation.SPNavigationSiteMapNode]::UpdateSPNavigationNode($node, $null, $name, $($node.Url), $description, $target, $audience, $false)
}
 
Write-Host "Configuring Navigation..."
$menuItems = "/site5", "/site4", "/site3", "/site2", "/site1"
Set-Navigation "https://test.mednet.med.ubc.ca/sites/intranet1/AboutUs/" $menuItems
Write-Host "Navigation Configuration completed"