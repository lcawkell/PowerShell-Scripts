
if ((Get-PSSnapin | where {$_.Name -like "*SharePoint*"}) -eq $null)
{
    Add-PSSnapin Microsoft.SharePoint.PowerShell
    Write-Host SharePoint Snapin Added
}
else
{
    Write-Host SharePoint Snapin already available
}



#

[xml]$LibraryStructure = Get-Content "C:\XML\Awards&Recognition.xml"

#$web = Get-SPWeb $LibraryStructure.structure.siteUrl
$libraryTemplate = [Microsoft.SharePoint.SPListTemplateType]::DocumentLibrary
$listTemplate = [Microsoft.SharePoint.SPListTemplateType]::GenericList

function CreateFolder
{
[CmdletBinding()]
Param(
[Parameter(Mandatory=$true,Position=1)]
[System.Xml.XmlElement]$folder,
[Parameter(Mandatory=$true,Position=2)]
[Microsoft.SharePoint.SPDocumentLibrary]$spLibraryf,
[Parameter(Mandatory=$true,Position=3)]
[AllowEmptyString()]
[string]$url
)

Write-Host Creating: $folder.name in $spLibraryf.name $url


$spFolder = $spLibraryF.AddItem($url,[Microsoft.SharePoint.SPFileSystemObjectType]::Folder,$folder.name)
$spFolder.Update()

        # Permissions
        $permissions = $folder.permissions

        if($permissions -ne $null)
        {
        
            $spFolder.BreakRoleInheritance($true)
            [Microsoft.SharePoint.SPRoleAssignmentCollection] $spRoleAssignments = $spFolder.RoleAssignments
            $count = $spRoleAssignments.count
            
            for([int] $oldPermission = 0; $oldPermission -lt $count; $oldPermission++)
            {
                $spRoleAssignments.Remove(0)
            }
        
            if($permissions.owner -ne $null)
            {
                foreach($owner in $permissions.owner)
                {
                    $group = $web.SiteGroups[$owner]
                    $roleAssignment = New-Object Microsoft.SharePoint.SPRoleAssignment($group)
                    $roleDefinition = $web.Site.RootWeb.RoleDefinitions["Full Control"]
                    $roleAssignment.RoleDefinitionBindings.Add($roleDefinition)
                    $spFolder.RoleAssignments.Add($roleAssignment)
                }
             }
             
            if($permissions.member -ne $null)
            {
                foreach($member in $permissions.member)
                {
                    $group = $web.SiteGroups[$member]
                    $roleAssignment = New-Object Microsoft.SharePoint.SPRoleAssignment($group)
                    $roleDefinition = $web.Site.RootWeb.RoleDefinitions["Contribute"]
                    $roleAssignment.RoleDefinitionBindings.Add($roleDefinition)
                    $spFolder.RoleAssignments.Add($roleAssignment)               
                }
             }
             
            if($permissions.visitor -ne $null)
            {
                foreach($visitor in $permissions.visitor)
                {
                    $group = $web.SiteGroups[$visitor]
                    $roleAssignment = New-Object Microsoft.SharePoint.SPRoleAssignment($group)
                    $roleDefinition = $web.Site.RootWeb.RoleDefinitions["Read"]
                    $roleAssignment.RoleDefinitionBindings.Add($roleDefinition)
                    $spFolder.RoleAssignments.Add($roleAssignment)
                }
             }
         
         }
         else
         {
            $spFolder.ResetRoleInheritance()
         }





if($folder.folder -ne $null)
{
            if($url -ne "")
        {
            $url = $url + "\"
        }
    foreach($innerFolder in $folder.folder)
    {
        CreateFolder $innerFolder -spLibraryF $spLibraryf -url ($url + $folder.name)
    }
}



}



function CreateLibrary
{
[CmdletBinding()]
Param(
[Parameter(Mandatory=$True,Position=1)]
[System.Object[]]$libraries,
[Parameter(Mandatory=$True,Position=2)]
$web
)
    
    
    
    foreach ($library in $libraries)
    {
    
        Write-Host Adding: $library.name
        if($web.Lists[$library.name] -eq $null)
        {
            $web.Lists.Add($library.name,$library.name,$libraryTemplate)
            $newLib = $web.Lists[$library.name]
            $newLib.OnQuickLaunch = $true
            $newLib.Update()
        }
        else
        {
            Write-Host Library $library.name Already Exists!
        }
        
        # Permissions
        $permissions = $library.permissions
        
        if($permissions -ne $null)
        {
        
            $newLib.BreakRoleInheritance($true)
            [Microsoft.SharePoint.SPRoleAssignmentCollection] $spRoleAssignments = $newLib.RoleAssignments
            $count = $spRoleAssignments.count
            
            for([int] $oldPermission = 0; $oldPermission -lt $count; $oldPermission++)
            {
                $spRoleAssignments.Remove(0)
            }
        
            if($permissions.owner -ne $null)
            {
                foreach($owner in $permissions.owner)
                {
                    $group = $web.SiteGroups[$owner]
                    $roleAssignment = New-Object Microsoft.SharePoint.SPRoleAssignment($group)
                    $roleDefinition = $web.Site.RootWeb.RoleDefinitions["Full Control"]
                    $roleAssignment.RoleDefinitionBindings.Add($roleDefinition)
                    $newLib.RoleAssignments.Add($roleAssignment)
                }
             }
             
            if($permissions.member -ne $null)
            {
                foreach($member in $permissions.member)
                {
                    $group = $web.SiteGroups[$member]
                    $roleAssignment = New-Object Microsoft.SharePoint.SPRoleAssignment($group)
                    $roleDefinition = $web.Site.RootWeb.RoleDefinitions["Contribute"]
                    $roleAssignment.RoleDefinitionBindings.Add($roleDefinition)
                    $newLib.RoleAssignments.Add($roleAssignment)               
                }
             }
             
            if($permissions.visitor -ne $null)
            {
                foreach($visitor in $permissions.visitor)
                {
                    $group = $web.SiteGroups[$visitor]
                    $roleAssignment = New-Object Microsoft.SharePoint.SPRoleAssignment($group)
                    $roleDefinition = $web.Site.RootWeb.RoleDefinitions["Read"]
                    $roleAssignment.RoleDefinitionBindings.Add($roleDefinition)
                    $newLib.RoleAssignments.Add($roleAssignment)
                }
             }
         
         }
         else
         {
            $newLib.ResetRoleInheritance()
         }
         
        
        $fields = $newLib.Fields
        
        if ($library.fields -ne $null)
        {
            foreach($field in $library.fields.field)
            {
                $fieldType = $field.type
                
                $spFieldType = [Microsoft.SharePoint.SPFieldType]::$fieldType
                
                # Name, Type, isRequired #
                $newField = $fields.AddFieldAsXml($field.OuterXml,$true,[Microsoft.SharePoint.SPAddFieldOptions]::AddFieldToDefaultView)
                
               
                
            }
        
        }
        
        if($library.folder -ne $null)
        {
            foreach($folder in $library.folder)
            {
                CreateFolder -folder $folder -spLibraryF $newLib -url $newLib.rootfolder.url
            }
        }
    }


}

function CreateList
{
[CmdletBinding()]
Param(
[Parameter(Mandatory=$True,Position=1)]
[System.Object[]]$lists,
[Parameter(Mandatory=$True,Position=2)]
$web
)

    
    
    foreach ($list in $lists)
    {
        $onquicklaunch = $FALSE
        
        if($list.onquicklaunch -eq "true")
        {
            $onquicklaunch = $TRUE
        }
    
        Write-Host Adding: $list.name
        if($web.Lists[$list.name] -eq $null)
        {
            $web.Lists.Add($list.name,$list.name,$listTemplate)
            $newList = $web.Lists[$list.name]
            $newList.OnQuickLaunch = $onquicklaunch
            $newList.Update()
        }
        else
        {
            Write-Host List $list.name Already Exists! ... skipping ...
        }
        
        
        
        # Permissions
        $permissions = $list.permissions
        
        if($permissions -ne $null)
        {
        
            $newList.BreakRoleInheritance($true)
            [Microsoft.SharePoint.SPRoleAssignmentCollection] $spRoleAssignments = $newList.RoleAssignments
            $count = $spRoleAssignments.count
            
            for([int] $oldPermission = 0; $oldPermission -lt $count; $oldPermission++)
            {
                $spRoleAssignments.Remove(0)
            }
        
            if($permissions.owner -ne $null)
            {
                foreach($owner in $permissions.owner)
                {
                    $group = $web.SiteGroups[$owner]
                    $roleAssignment = New-Object Microsoft.SharePoint.SPRoleAssignment($group)
                    $roleDefinition = $web.Site.RootWeb.RoleDefinitions["Full Control"]
                    $roleAssignment.RoleDefinitionBindings.Add($roleDefinition)
                    $newList.RoleAssignments.Add($roleAssignment)
                }
             }
             
            if($permissions.member -ne $null)
            {
                foreach($member in $permissions.member)
                {
                    $group = $web.SiteGroups[$member]
                    $roleAssignment = New-Object Microsoft.SharePoint.SPRoleAssignment($group)
                    $roleDefinition = $web.Site.RootWeb.RoleDefinitions["Contribute"]
                    $roleAssignment.RoleDefinitionBindings.Add($roleDefinition)
                    $newList.RoleAssignments.Add($roleAssignment)               
                }
             }
             
            if($permissions.visitor -ne $null)
            {
                foreach($visitor in $permissions.visitor)
                {
                    $group = $web.SiteGroups[$visitor]
                    $roleAssignment = New-Object Microsoft.SharePoint.SPRoleAssignment($group)
                    $roleDefinition = $web.Site.RootWeb.RoleDefinitions["Read"]
                    $roleAssignment.RoleDefinitionBindings.Add($roleDefinition)
                    $newList.RoleAssignments.Add($roleAssignment)
                }
             }
         
         }
         else
         {
            $newList.ResetRoleInheritance()
         }

        
        $fields = $newList.Fields
        
        if ($list.fields -ne $null)
        {
            foreach($field in $list.fields.field)
            {
                $fieldType = $field.type
                
                $spFieldType = [Microsoft.SharePoint.SPFieldType]::$fieldType
                
                # Name, Type, isRequired #
                $newField = $fields.AddFieldAsXml($field.OuterXml,$true,[Microsoft.SharePoint.SPAddFieldOptions]::AddFieldToDefaultView)
                
               
                
            }
        
        }
        

    }


}

function DeleteLibrary
{
[CmdletBinding()]
Param(
[Parameter(Mandatory=$True,Position=1)]
[System.Object[]]$libraries
)

    
    
    foreach ($library in $libraries)
    {
        Write-Host Deleting: $library.name
        $spLibrary = $web.lists[$library.name]
        $spLibrary.Delete()
    }


}

function DeleteList
{
[CmdletBinding()]
Param(
[Parameter(Mandatory=$True,Position=1)]
[System.Object[]]$lists
)

    
    
    foreach ($list in $lists)
    {
        Write-Host Deleting: $list.name
        $spList = $web.lists[$list.name]
        $spList.Delete()
    }


}

function CreateGroups
{
[CmdletBinding()]
Param(
[Parameter(Mandatory=$True,Position=1)]
[System.Object[]]$groups,
[Parameter(Mandatory=$True,Position=2)]
$web
)


    
    foreach($group in $groups)
    {
    
        $groupName = $group.name
        $groupDescription = $group.description
        
        try
        {
            Write-Host Adding new group: $groupName
            $web.SiteGroups.Add($groupName,$web.EnsureUser("fom\lcawkell_admin"),$web.EnsureUser("fom\lcawkell_admin"),$groupDescription);
            $newGroup = $web.SiteGroups[$group.name]

            try # See if the group owner is a user
            {
                $newGroup.Owner = $web.EnsureUser($group.owner)
            }
            catch [system.exception] # Group owner must be another group
            {
                try
                {
                    $newGroup.Owner = $web.SiteGroups[$group.owner]
                }
                catch [system.exception] # No owner specified or there was an order of operations problem
                {
                    $newGroup.Owner = $newGroup
                }
            }

            $newGroup.RemoveUser($web.EnsureUser("fom\lcawkell_admin"))
            $newGroup.Update()
            
            if($group.member -ne $null)
            {
                foreach($member in $group.member)
                {
                    "Adding member " + $member
                    $newGroup.AddUser($web.EnsureUser($member))
                }
            }
        }
        catch [system.exception]
        {
            Write-Host Group $group already exists...
        }
    }

}

function RemoveGroups
{
[CmdletBinding()]
Param(
[Parameter(Mandatory=$True,Position=1)]
[System.Object[]]$groups
)

foreach($group in $groups)
{
    try
    {
     $web.SiteGroups.Remove($group.name) 
     "Removed " + $group.name
    }
    catch [system.exception]
    {
     Write-Host Group $group.name doesn"'"t seem to exist.
    }
}

}

function CreateWebs($baseUrl, $site, [int]$progressid, $level) 
{ 
    $webcount = $site.ChildNodes.Count 
    $counter = 0
    $rootWeb = (Get-SPWeb $baseUrl).site.rootweb.url
    
   
    foreach ($web in $site.web) 
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
        
        $newSite = Get-SPWeb ($baseUrl + $web.url) -ErrorVariable err -ErrorAction SilentlyContinue

        if($err)
        {

            Write-Host "Creating $($web.name) $($baseUrl)$($web.url)... TopNav:$($topnav) SideNav:$($sidenav)" 
            $newSite = New-SPWeb -Url "$($baseUrl)$($web.url)" -AddToQuickLaunch:$false -AddToTopNav:$topnav -Confirm:$false -Name "$($web.name)" -Template "BLANKINTERNET#0" -UseParentTopNav:$true
            
            Write-Host "Enabling Branding Application Feature on $newSite"
            Enable-SPFeature -Identity c6fb1fb5-01fc-454c-a893-5adabfce7235 -Url "$($baseUrl)$($web.url)"

            $page = $newSite.GetFile($newSite.Url + "/Pages/default.aspx")
            $page.CheckOut("Online", $null)
            $spWpManager = $newSite.GetLimitedWebPartManager($page.Url, [System.Web.UI.WebControls.WebParts.PersonalizationScope]::Shared)
            $spWPManager.DeleteWebPart($spWPManager.WebParts[0])
            $page.Properties["PublishingPageLayout"] = $rootWeb + "/_catalogs/masterpage/ubcfom_inner_1col.aspx, ubcfom_inner_1col"
            $page.Update()
            $page.CheckIn("Checked in by PowerShell", [Microsoft.SharePoint.SPCheckinType]::MajorCheckIn)
            $page.Publish("Published by PowerShell")
            $page.Approve("Approved by PowerShell")

            
            Start-Sleep -s 2
            
            CleanSite $newSite $level
            
            if($web.library -ne $null)
            {
                CreateLibrary $web.library $newSite
            }
            
            if($web.list -ne $null)
            {
                CreateList $web.list $newSite
            }
            
            
            # Permissions
        $permissions = $web.permissions
        
        if($permissions -ne $null)
        {
        
            $newSite.BreakRoleInheritance($true)
            [Microsoft.SharePoint.SPRoleAssignmentCollection] $spRoleAssignments = $newSite.RoleAssignments
            $count = $spRoleAssignments.count
            
            for([int] $oldPermission = 0; $oldPermission -lt $count; $oldPermission++)
            {
                $spRoleAssignments.Remove(0)
            }
        
            if($permissions.owner -ne $null)
            {
                foreach($owner in $permissions.owner)
                {
                    $group = $newSite.SiteGroups[$owner]
                    $roleAssignment = New-Object Microsoft.SharePoint.SPRoleAssignment($group)
                    $roleDefinition = $newSite.Site.RootWeb.RoleDefinitions["Full Control"]
                    $roleAssignment.RoleDefinitionBindings.Add($roleDefinition)
                    $newSite.RoleAssignments.Add($roleAssignment)
                }
             }
             
            if($permissions.member -ne $null)
            {
                foreach($member in $permissions.member)
                {
                    $group = $newSite.SiteGroups[$member]
                    $roleAssignment = New-Object Microsoft.SharePoint.SPRoleAssignment($group)
                    $roleDefinition = $newSite.Site.RootWeb.RoleDefinitions["Contribute"]
                    $roleAssignment.RoleDefinitionBindings.Add($roleDefinition)
                    $newSite.RoleAssignments.Add($roleAssignment)               
                }
             }
             
            if($permissions.visitor -ne $null)
            {
                foreach($visitor in $permissions.visitor)
                {
                    $group = $newSite.SiteGroups[$visitor]
                    $roleAssignment = New-Object Microsoft.SharePoint.SPRoleAssignment($group)
                    $roleDefinition = $newSite.Site.RootWeb.RoleDefinitions["Read"]
                    $roleAssignment.RoleDefinitionBindings.Add($roleDefinition)
                    $newSite.RoleAssignments.Add($roleAssignment)
                }
             }
         
         }
         else
         {
            $newSite.ResetRoleInheritance()
         }

            
        }
        else
        {
            Write-Host $web.name already exists. Skipping...
        }
        
        if ($web.web.Count -ne $null) 
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
        if($level -ge 3)
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

function CreateSite
{
[CmdletBinding()]
Param(
[Parameter(Mandatory=$True,Position=1)]
[System.Object[]]$sites,
[Parameter(Mandatory=$True,Position=2)]
[string]$baseUrl
)

Start-SPAssignment -global


    foreach($site in $sites)
    {
    
        
        $spSite = Get-SPSite ($baseUrl + $site.url) -ErrorVariable err -ErrorAction SilentlyContinue

        if($err)
        {

            $spSite = New-SPSite ($baseUrl + $site.url) -OwnerAlias "fom\lcawkell_admin" -Name $site.name -Template "STS#1" -Description $site.description
            Write-Host "Enabling Server Publishing Infrastructure"
            Enable-SPFeature -Identity "f6924d36-2fa8-4f0b-b16d-06b7250180fa" -Url "$($baseUrl)$($site.url)"
            Write-Host "Enabled! ... wait 5 seconds (smelling flowers)"
            Start-Sleep -s 5
            Write-Host "Enabling Branding Infrastructure"
            Enable-SPFeature -Identity "4fbba0f7-453e-40a2-b268-345f8bb9ec88" -Url "$($baseUrl)$($site.url)"
            Write-Host "Enabled! ...  wait 5 seconds (picking flowers)"
            Start-Sleep -s 5
            $web = $site.RootWeb
           # ActivateFeature $brandingFeatureActivationFeatureID "$($baseUrl)$($web.url)" "Branding Activation Feature" $false $false
           # ActivateFeature "94c94ca6-b32f-4da9-a9e3-1f3d343d7ecb" "$($baseUrl)$($web.url)" "Publishing Web" $false $false
            $linkNode = New-Object Microsoft.SharePoint.Navigation.SPNavigationNode($site.name,($baseUrl + $site.url),$true)
            $web = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($spSite.RootWeb)
            $web.Navigation.GlobalNavigationNodes.AddAsFirst($linkNode)
            Enable-SPFeature -Identity "c6fb1fb5-01fc-454c-a893-5adabfce7235" -Url $web.Url
        }
        
        
        $web = Get-SPWeb ($baseUrl + $site.url)
        
        CreateGroups $LibraryStructure.structure.sites.site.group $web
        
        # Permissions
        $permissions = $site.permissions
        
        if($permissions -ne $null)
        {
        
            if($permissions.owner -ne $null)
            {
                foreach($owner in $permissions.owner)
                {
                    $group = $spSite.RootWeb.SiteGroups[$owner]
                    $roleAssignment = New-Object Microsoft.SharePoint.SPRoleAssignment($group)
                    $roleDefinition = $web.Site.RootWeb.RoleDefinitions["Full Control"]
                    $roleAssignment.RoleDefinitionBindings.Add($roleDefinition)
                    $spSite.RootWeb.RoleAssignments.Add($roleAssignment)
                }
             }
             
            if($permissions.member -ne $null)
            {
                foreach($member in $permissions.member)
                {
                    $group = $spSite.RootWeb.SiteGroups[$member]
                    $roleAssignment = New-Object Microsoft.SharePoint.SPRoleAssignment($group)
                    $roleDefinition = $web.Site.RootWeb.RoleDefinitions["Contribute"]
                    $roleAssignment.RoleDefinitionBindings.Add($roleDefinition)
                    $spSite.RootWeb.RoleAssignments.Add($roleAssignment)               
                }
             }
             
            if($permissions.visitor -ne $null)
            {
                foreach($visitor in $permissions.visitor)
                {
                    $group = $spSite.RootWeb.SiteGroups[$visitor]
                    $roleAssignment = New-Object Microsoft.SharePoint.SPRoleAssignment($group)
                    $roleDefinition = $web.Site.RootWeb.RoleDefinitions["Read"]
                    $roleAssignment.RoleDefinitionBindings.Add($roleDefinition)
                    $spSite.RootWeb.RoleAssignments.Add($roleAssignment)
                }
             }
         
         }


        
        

        

        CreateWebs ($baseUrl+$site.url) $site 1 3
        
    
      
    }

Stop-SPAssignment -global
}

function DestroySite
{
[CmdletBinding()]
Param(
[Parameter(Mandatory=$True,Position=1)]
[System.Object[]]$sites,
[Parameter(Mandatory=$True,Position=2)]
[string]$baseUrl
)

Start-SPAssignment -global


    foreach($site in $sites)
    {

        
        $spSite = Get-SPSite ($baseUrl + $site.url) -ErrorVariable err -ErrorAction SilentlyContinue

        if($err)
        {
         Write-Host site: $site.name does not exist
        }
        else
        {
            foreach($web in $site.web)
            {
                $spWeb = Get-SPWeb ($baseUrl + $site.url + $web.url) -ErrorVariable err -ErrorAction SilentlyContinue
                if($err)
                {
                    Write-Host $web.name does not exist
                }
                else
                {
                    RemoveSPWebRecursively $spWeb
                }
            }
            Remove-SPSite $spSite -Confirm:$false
        }
        

        
    
      
    }

Stop-SPAssignment -global
}

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



#CreateSite $LibraryStructure.structure.sites.site $LibraryStructure.structure.root
#DestroySite $LibraryStructure.structure.sites.site $LibraryStructure.structure.root
#CreateWebs ($baseUrl) $LibraryStructure.structure.webs 1 1