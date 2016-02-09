#Requires -Version 3
#Requires -PSSnapin Microsoft.SharePoint.PowerShell
#Requires -Module ActiveDirectory
#Requires -RunAsAdministrator

function Save-SPSiteToXml
{
<#


TODO



#>
[CmdletBinding()]
Param(
[Parameter(Mandatory=$true,ParameterSetName="SiteDocument")]
[Parameter(Mandatory=$true,ParameterSetName="SiteElement")]
[Microsoft.SharePoint.SPSite]$site,
[Parameter(Mandatory=$true,ParameterSetName="WebDocument")]
[Parameter(Mandatory=$true,ParameterSetName="WebElement")]
[Microsoft.SharePoint.SPWeb]$web,
[Parameter(Mandatory=$true,ParameterSetName="SiteElement")]
[Parameter(Mandatory=$true,ParameterSetName="WebElement")]
[System.Xml.XmlElement]$parentElement,
[Parameter(Mandatory=$true,ParameterSetName="SiteDocument")]
[Parameter(Mandatory=$true,ParameterSetName="WebDocument")]
[System.Xml.XmlDocument]$parentDocument,
[Parameter(Mandatory=$false)]
[System.Xml.XmlElement]$xmlInput,
[Parameter(Mandatory=$false)]
[Switch]$topLevel
)
    
    Write-Verbose "Creating our blacklist of lists to ignore"

    #region Blacklist

    $blackList= {}.Invoke()

    $blacklist.Add("Theme Gallery")
    $blacklist.Add("Spelling")
    $blacklist.Add("Style Library")
    $blacklist.Add("Master Page Gallery")
    $blacklist.Add("Maintenance Log Library")
    $blacklist.Add("List Template Gallery")
    $blacklist.Add("Converted Forms")
    $blacklist.Add("TimerJobLogs")
    $blacklist.Add("Web Part Gallery")
    $blacklist.Add("wfpub")
    $blacklist.Add("Events")
    $blacklist.Add("News")
    $blacklist.Add("Events_Current")
    $blacklist.Add("Cache Profiles")
    $blacklist.Add("Content and Structure Reports")
    $blacklist.Add("Content type publishing error log")
    $blacklist.Add("Critical Message")
    $blacklist.Add("Customized Reports")
    $blacklist.Add("Form Templates")
    $blacklist.Add("Long Running Operation Status")
    $blacklist.Add("solutions")
    $blacklist.Add("Buildings")
    $blacklist.Add("Events")
    $blacklist.Add("Faculty of Medicine maps")
    $blacklist.Add("Historical Photos")
    $blacklist.Add("People")
    $blacklist.Add("Solutions Gallery")
    $blacklist.Add("User Information List")
    $blacklist.Add("Workflow History")

    foreach($item in $blackList){Write-Verbose $item}

    #endregion

    $uploadList = @{}

    foreach($xmlUploadFile in $xmlInput.OwnerDocument.input.reorganize.site.upload.file)
    {
        $uploadList.Add($xmlUploadFile.url, $xmlUploadFile.path)
    }

    if($site -ne $null) # If a site has been given
    {
        Write-Host "Saving site $($site.RootWeb.Title)"

        if ($parentElement -eq $null)
        {
            $xmlDocument = $parentDocument
            $parentElement = $xmlDocument.CreateElement("SiteStructure")
            $parentElement.SetAttribute("path", "C:\out\")
            $xmlDocument.AppendChild($parentElement) | Out-Null
            $xmlElement = $xmlDocument.CreateElement("Site")
            $xmlDocument.AppendChild($xmlElement) | Out-Null
        }
        elseif ($parentDocument -eq $null)
        {
            $xmlDocument = $parentElement.OwnerDocument
            $xmlElement = $xmlDocument.CreateElement("Site")
            $parentElement.AppendChild($xmlElement) | Out-Null
        }


            $web = $site.RootWeb
            $url = $site.Url

        # Get site owner. If site owner no longer exists in AD then use current user (the person running this script)
        if((Get-ADUser -ErrorAction SilentlyContinue -Identity $site.Owner.UserLogin.Substring($site.Owner.UserLogin.LastIndexOf('\')+1) | Where {$_.Enabled -match "True"}) -eq $null)
        {
            $owner = "fom\"+[Environment]::UserName
            $ownerEmail = (Get-ADUser ($owner.Substring(4)) -Properties mail).mail
        }
        else
        {
            $owner = $site.Owner.UserLogin.Substring($site.Owner.UserLogin.LastIndexOf('|')+1)
            $ownerEmail = $site.Owner.Email
        }

        # Any site specified attributes go here
        $xmlElement.SetAttribute("ownerAlias", $owner)
        $xmlElement.SetAttribute("ownerEmail", $ownerEmail)
        $xmlElement.SetAttribute("destination", $xmlDocument.sitestructure.destination)

        # Record Groups
        $xmlGroups = $xmlDocument.CreateElement("groups")
        $xmlElement.AppendChild($xmlGroups) | Out-Null

        foreach($group in $web.Groups)
        {
            $xmlGroup = $xmlDocument.CreateElement("group")
            $xmlGroup.SetAttribute("owner", $group.owner)
            $xmlGroup.SetAttribute("defaultuser", $group.owner)
            $xmlGroup.SetAttribute("description", $group.Description)
            $xmlGroup.SetAttribute("name", $group.Name)

            foreach($user in $group.Users)
            {
                $xmlUser = $xmlDocument.CreateElement("user")
                $xmlUser.InnerText = $($user.UserLogin)
                $xmlGroup.AppendChild($xmlUser) | Out-Null
            }

            $xmlGroups.AppendChild($xmlGroup) | Out-Null
        }

    }
    else # If a web has been given
    {
        Write-Host "Saving web $($web.Title)"
        if ($parentElement -eq $null)
        {
            $xmlDocument = $parentDocument
            $xmlElement = $xmlDocument.CreateElement("Web")
            $xmlDocument.AppendChild($xmlElement) | Out-Null
        }
        elseif ($parentDocument -eq $null)
        {
            $xmlDocument = $parentElement.OwnerDocument
            $xmlElement = $xmlDocument.CreateElement("Web")
            $parentElement.AppendChild($xmlElement) | Out-Null
        }

        # Any web specific variables go here
        $url = $web.ServerRelativeUrl #($web.Url).Substring($web.Url.LastIndexOf("/"))

        

        # Any web specific attributes go here

    }

    $workingDirectory = ($parentElement.path)
    $webPath = $workingDirectory + "\" + $web.Title

    # The publishing version of the web contains navigation settings
    Write-Verbose "Trying to get the publishing version of the web..."
    $publishingWeb = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($web)
    $pubWebNavigation = $publishingWeb.Navigation

    # All generic attributes go here
    $xmlElement.SetAttribute("name", $web.Name)
    $xmlElement.SetAttribute("title", $web.Title)
    $xmlElement.SetAttribute("url", $url)
    $xmlElement.SetAttribute("description", $web.Description)
    $xmlElement.SetAttribute("path", $webPath)
    $xmlElement.SetAttribute("template", $web.WebTemplate+"#"+$web.Configuration)
    $xmlElement.SetAttribute("inheritglobal", $pubWebNavigation.InheritGlobal)
    $xmlElement.SetAttribute("inheritcurrent", $pubWebNavigation.InheritCurrent)
    $xmlElement.SetAttribute("globalincludesubsites", $pubWebNavigation.GlobalIncludeSubSites)
    $xmlElement.SetAttribute("globalincludepages", $pubWebNavigation.GlobalIncludePages)
    $xmlElement.SetAttribute("currentshowsiblings", $pubWebNavigation.ShowSiblings)
    $xmlElement.SetAttribute("currentincludesubsites", $pubWebNavigation.CurrentIncludeSubSites)
    $xmlElement.SetAttribute("currentincludepages", $pubWebNavigation.CurrentIncludePages)

    
    # Record Permissions if not inheriting from parent
    if($web.HasUniquePerm)
    {
        Write-Host "Recording permissions..."
        $xmlPermissions = $xmlDocument.CreateElement("permissions")
        foreach($assignment in $web.RoleAssignments)
        {
            $xmlPermission = $xmlDocument.CreateElement("assignment")
            $xmlPermission.SetAttribute("member", $assignment.Member.LoginName)
            
            foreach($role in $assignment.RoleDefinitionBindings)
            {
                if($role -ne "LimitedAccess")
                {
                    $xmlRole = $xmlDocument.CreateElement("role")
                    $xmlRole.InnerText = $role.Name
                    $xmlPermission.AppendChild($xmlRole) | Out-Null
                }
            }

            $xmlPermissions.AppendChild($xmlPermission) | Out-Null
        }
        $xmlElement.AppendChild($xmlPermissions) | Out-Null
    }

    $xmlNavigation = $xmlDocument.CreateElement("navigation")
    $xmlElement.AppendChild($xmlNavigation) | Out-Null

    $xmlNavigation.SetAttribute("inheritglobal", $pubWebNavigation.InheritGlobal)
    $xmlNavigation.SetAttribute("inheritcurrent", $pubWebNavigation.InheritCurrent)
    $xmlNavigation.SetAttribute("globalincludesubsites", $pubWebNavigation.GlobalIncludeSubSites)
    $xmlNavigation.SetAttribute("globalincludepages", $pubWebNavigation.GlobalIncludePages)
    $xmlNavigation.SetAttribute("currentshowsiblings", $pubWebNavigation.ShowSiblings)
    $xmlNavigation.SetAttribute("currentincludesubsites", $pubWebNavigation.CurrentIncludeSubSites)
    $xmlNavigation.SetAttribute("currentincludepages", $pubWebNavigation.CurrentIncludePages)

    Write-Host "Saving lists..."
    foreach($list in $web.Lists)
    {
        if(!$blackList.Contains($list.Title))
        {
            Save-SPListToXml -list $list -xmlElement $xmlElement -uploadList $uploadList
        }  
        else
        {
            Write-Verbose "Not saving list: $($list.Title)... It's been blacklisted"
        }
    }

    if([string]::IsNullOrEmpty($xmlInput))
    {
        foreach($subweb in $web.Webs)
        {
            if(($subweb.ParentWeb.Title -eq "MedNet") -and ($topLevel))
            {
                Save-SPSiteToXml -web $subweb -parentElement $xmlElement -topLevel
            }
            elseif (!$topLevel)
            {
                Save-SPSiteToXml -web $subweb -parentElement $xmlElement
            }
        }
    }
    else
    {
        foreach($xmlWeb in $xmlInput.web)
        {
            $subweb = $web.Webs[$xmlWeb.names]
            if(($subweb.ParentWeb.Title -eq "MedNet") -and ($topLevel))
            {
                Save-SPSiteToXml -web $subweb -parentElement $xmlElement -xmlInput $xmlWeb -topLevel
            }
            elseif (!$topLevel)
            {
                Save-SPSiteToXml -web $subweb -parentElement $xmlElement -xmlInput $xmlWeb
            }
        }
    }



    #$site.Dispose()
    $web.Dispose()

}

function Save-SPListToXml
{
<#


TODO



#>
[CmdletBinding()]
Param
(
[Parameter (Mandatory=$true)]
[Microsoft.SharePoint.SPList] $list,
[Parameter (Mandatory=$true, ParameterSetName="xmlDocument")]
[System.Xml.XMLDocument] $xmlDocument,
[Parameter (Mandatory=$true, ParameterSetName="xmlElement")]
[System.Xml.XMLElement]$xmlElement,
[System.Collections.HashTable]$uploadList
)
    
    #region Column Blacklist
    $columnBlackList= {}.Invoke()

    $columnBlackList.Add("Content Type ID")
    $columnBlackList.Add("Approver Comments")
    $columnBlackList.Add("File Type")          
    $columnBlackList.Add("Published")
    $columnBlackList.Add("Content Type")
    $columnBlackList.Add("Has Copy Destinations")        
    $columnBlackList.Add("Copy Source")    
    $columnBlackList.Add("owshiddenversion")     
    $columnBlackList.Add("Workflow Version")             
    $columnBlackList.Add("UI Version")         
    $columnBlackList.Add("Version")
    $columnBlackList.Add("Approval Status")              
    $columnBlackList.Add("Edit")                               
    $columnBlackList.Add("Select")                
    $columnBlackList.Add("Instance ID")                  
    $columnBlackList.Add("Order")                  
    $columnBlackList.Add("GUID")                  
    $columnBlackList.Add("Workflow Instance ID")                 
    $columnBlackList.Add("URL Path")               
    $columnBlackList.Add("Path")
    $columnBlackList.Add("Item Type")                
    $columnBlackList.Add("Sort Type")                           
    $columnBlackList.Add("Unique Id")            
    $columnBlackList.Add("Client Id")            
    $columnBlackList.Add("ProgId")            
    $columnBlackList.Add("ScopeId")                 
    $columnBlackList.Add("HTML File Type")               
    $columnBlackList.Add("Edit Menu Table Start")                   
    $columnBlackList.Add("Edit Menu Table End")                             
    $columnBlackList.Add("Type")    
    $columnBlackList.Add("Server Relative URL")               
    $columnBlackList.Add("Encoded Absolute URL")     
    $columnBlackList.Add("File Name")             
    $columnBlackList.Add("Property Bag")             
    $columnBlackList.Add("Level")               
    $columnBlackList.Add("Is Current Version")                
    $columnBlackList.Add("Item Child Count")                
    $columnBlackList.Add("Folder Child Count")
    $columnBlackList.Add("Content Category")
    $columnBlackList.Add("Automatic Update")
    $columnBlackList.Add("Reusable HTML")
    $columnBlackList.Add("Reusable Text")
    $columnBlackList.Add("Attachments")
    $columnBlackList.Add("Page Content")
    $columnBlackList.Add("Target Audiences")
    $columnBlackList.Add("Variation Relationship Link")
    $columnBlackList.Add("Source Version (Converted Document)")
    $columnBlackList.Add("Document Concurrency Number")
    $columnBlackList.Add("File Size")
    $columnBlackList.Add("Style Definitions")
    $columnBlackList.Add("Check In Comment")
    $columnBlackList.Add("Virus Status")
    $columnBlackList.Add("ID")
    #$columnBlackList.Add("")

    #endregion

    if($xmlElement -ne $null)
    {
        $xmlDocument = $xmlElement.OwnerDocument
    }
    else
    {
        $xmlElement = $xmlDocument.CreateElement("ListStructure")
        $xmlDocument.AppendChild($xmlElement) | Out-Null
    }

    Write-Verbose "Trying to set path variable to XML path: $($xmlDocument.FirstChild.path)"
    $path = $xmlElement.path

    if([string]::IsNullOrEmpty($path))
    {
        Write-Debug "Path doesn't exist in XML document. Using C:\out\"
        $path = "C:\out\"
    } 
    

    if ($list.BaseType -eq "DocumentLibrary")
    {

       $xmlList = $xmlDocument.CreateElement("library")
       $xmlList.SetAttribute("title", $list.Title)
       $xmlList.SetAttribute("urlTitle", $list.RootFolder.Name)
       $xmlList.SetAttribute("path", $path)
       $xmlList.SetAttribute("template", $list.BaseTemplate)
       $xmlList.SetAttribute("enablemoderation", $list.EnableModeration)
       $xmlList.SetAttribute("enableminorversions", $list.EnableMinorVersions)
       $xmlList.SetAttribute("enableversioning", $list.EnableVersioning)
       $xmlElement.AppendChild($xmlList) | Out-Null

       Save-SPFilesToXml -folder $list.RootFolder -xmlElement $xmlList -columnBlacklist $columnBlackList -uploadList $uploadList
        

    }else # Usually this means it's a list
    {
        $xmlList = $xmlDocument.CreateElement("list")
        $xmlList.SetAttribute("title", $list.Title)
        $xmlList.SetAttribute("urlTitle", $list.RootFolder.Name)
        $xmlList.SetAttribute("template", $list.BaseTemplate)
        $xmlElement.AppendChild($xmlList) | Out-Null



        $xmlListItems = $xmlDocument.CreateElement("items")
        $xmlList.AppendChild($xmlListItems) | Out-Null

        foreach($item in $list.Items) # Gather information about the list items to re-add all items
        {
            $xmlItem = $xmlDocument.CreateElement("item")
            $xmlItem.SetAttribute("name", $item.StaticName)
            $xmlItem.SetAttribute("title", $item.Title)
            
            foreach($itemField in $item.Fields) # The list values are in each column
            {
                if(!$columnBlackList.Contains($itemField.Title)) # We don't care about columns in the blacklist
                {
                    $xmlItemField = $xmlDocument.CreateElement("itemfield")
                    $xmlItemField.SetAttribute("staticname", $itemField.StaticName)
                    $xmlItemField.SetAttribute("title", $itemField.Title)
                    $xmlItemField.InnerText = $item[$itemField.Title]
                    #$xmlItemField.SetAttribute("value", $item[$itemField.Title])
                    $xmlItem.AppendChild($xmlItemField) | Out-Null
                }
            }
            $xmlListItems.AppendChild($xmlItem) | Out-Null
        }
    }

    $xmlListFields = $xmlDocument.CreateElement("fields")
    $xmlList.AppendChild($xmlListFields) | Out-Null
  
    foreach($field in $list.Fields) # Gather information about fields to recreate the list
    {
        if(($field.FromBaseType -ne $true) -and ($field.Hidden -ne $true)) # Base columns will be created automatically with the list
        {
            $xmlField = $xmlDocument.CreateElement("field")
            $xmlField.SetAttribute("name", $field.StaticName)
            $xmlField.SetAttribute("title", $field.Title)
            $xmlField.InnerText = $field.SchemaXml
            $xmlListFields.AppendChild($xmlField) | Out-Null
        }
    }
    
    $xmlListViews = $xmlDocument.CreateElement("views")
    $xmlList.AppendChild($xmlListViews) | Out-Null

    foreach($view in $list.Views)
    {
        $xmlView = $xmlDocument.CreateElement("view")
        $xmlView.SetAttribute("title", $view.Title)
        $xmlView.SetAttribute("query", $view.Query)
        $xmlView.SetAttribute("rowlimit", $view.RowLimit)
        $xmlView.SetAttribute("paged", $view.Paged)
        $xmlView.SetAttribute("defaultview", $view.DefaultView)
        $xmlView.SetAttribute("viewfields", $view.ViewFields)
        $xmlListViews.AppendChild($xmlView) | Out-Null
    }

        # Record Permissions if not inheriting from parent
    if($list.HasUniqueRoleAssignments)
    {
        $xmlPermissions = $xmlDocument.CreateElement("permissions")
        foreach($permission in $list.Permissions)
        {
            $xmlPermission = $xmlDocument.CreateElement("permission")
            $xmlPermission.SetAttribute("member", $permission.Member)
            $xmlPermission.SetAttribute("permissionmask", $permission.PermissionMask)
            $xmlPermissions.AppendChild($xmlPermission) | Out-Null
        }
        $xmlList.AppendChild($xmlPermissions) | Out-Null
    }


}

function Save-SPFilesToXml
{
<#


TODO



#>
[CmdletBinding()]
Param
(
[Parameter (Mandatory=$true)]
[System.Xml.XmlElement]$xmlElement,
[Parameter (Mandatory=$true)]
[Microsoft.SharePoint.SPFolder]$folder,
[System.Object]$columnBlacklist,
[System.Collections.Hashtable]$uploadList
)
        
        if($columnBlacklist -eq $null)
        {
            $columnBlacklist = {}.Invoke()

            #columnBlacklist.Add("")
        }


        $list = $folder.DocumentLibrary
        $xmlDocument = $xmlElement.OwnerDocument

        
    if(($folder.Files.Count -gt 0) -or ($folder.SubFolders.Count -gt 0))
    {
        $path = $xmlElement.path + "\" + $folder.Name
        $xmlFolder = $xmlDocument.CreateElement("folder")
        $xmlFolder.SetAttribute("path", $path)
        $xmlFolder.SetAttribute("name", $folder.Name)
        $xmlFolder.SetAttribute("urlname", $folder.Url.Substring(0))
        $xmlElement.AppendChild($xmlFolder) | Out-Null
        
        Write-Debug "Creating a new folder with the path $path"
        if((Test-Path $path) -ne $true) {New-Item $path -ItemType directory | Out-Null}
         
        foreach($file in $folder.Files)
        {

            $filePath = $path+"\"+$($file.Name)
            
            if($uploadList.ContainsKey(($folder.ServerRelativeUrl + "/" + $file.Name)))
            {
                $inputFile = Get-Item -Path ($xmlElement.OwnerDocument.sitestructure.input + $uploadList[($folder.ServerRelativeUrl + "/" + $file.name)])
                $inputFile.CopyTo($filePath)
            }
            else
            {
                # Copy the file to the system drive
                
                $fileBinary = $file.OpenBinary()
                $fileStream = New-Object System.IO.FileStream(($filePath), [System.IO.FileMode]::Create)
                $binaryWriter = New-Object System.IO.BinaryWriter($fileStream)
                $binaryWriter.Write($fileBinary)
                $binaryWriter.Close()
            }

            # Update the XML
            $xmlFile = $xmlDocument.CreateElement("file")
            $xmlFile.SetAttribute("name", $file.Name)
            $xmlFile.SetAttribute("title", $file.Title)
            $xmlFile.SetAttribute("path", $filePath)
            
            $item = $file.Item

            foreach ($field in $item.Fields)
            {
                if(!($columnBlacklist.Contains($field.Title)))
                {
                    $xmlItemField = $xmlDocument.CreateElement("itemField")
                    $xmlItemField.SetAttribute("staticname", $field.StaticName)
                    $xmlItemField.SetAttribute("title", $field.Title)
                    $xmlItemField.InnerText = $item[$field.Title]
                    $xmlFile.AppendChild($xmlItemField) | Out-Null
                }
            }


            #if($($list.Title) -eq "Pages")
            #{
            #    $xmlFile.SetAttribute("layout", $file.Properties["PublishingPageLayout"])
            #}

            $xmlFolder.AppendChild($xmlFile) | Out-Null

        } #end foreach

        foreach($subFolder in $folder.SubFolders)
        {
            Save-SPFilesToXml -xmlElement $xmlFolder -folder $subFolder -columnBlacklist $columnBlacklist -uploadList $uploadList
        }

    } #end if
    else
    {
        Write-Debug "There are no files or folders in the folder: $($folder.url)"
    }



}

function New-SPSiteFromXml
{
    Param
    (
    [string]$xmlPath
    )

    ##########################
    #                        #
    # Set up directory & XML #
    #                        #  
    ##########################

    $xml = New-Object XML
    $xml.Load($xmlPath)


    foreach($xmlSite in $xml.sitestructure.site)
    {
        New-SPWebFromXml -parentElement $xmlSite
    }

}

function New-SPWebFromXml
{
    Param(
    [System.Xml.XMLElement]$parentElement
    )

    #region Creating site or web

    $url = ""


    
    if($parentElement.LocalName -eq "Site")
    {
        if([string]::IsNullOrEmpty(($url = $parentElement.destination)))
        {
            $url = $parentElement.url
        }

        Write-Host "Create a new site: $($parentElement.Title)"
        $site = New-SPSite -Name $parentElement.title -Url $url -Template $xmlSite.template -Description $parentElement.description -OwnerAlias $parentElement.ownerAlias -OwnerEmail $parentElement.ownerEmail -CompatibilityLevel 15
        Write-Host "Done!" -ForegroundColor Green
        $web = $site.RootWeb
        

        Sync-SPBrandingFiles -inputDirectory $parentElement.OwnerDocument.sitestructure.input -site $site

        $web.CustomMasterUrl = "$($web.ServerRelativeUrl)/_catalogs/masterpage/MedNetPublishing.master"
        $web.MasterUrl = "$($web.ServerRelativeUrl)/_catalogs/masterpage/MedNetPublishing.master"
        $web.Update()

    }elseif($parentElement.LocalName -eq "Web")
    {
        $url = $parentElement.OwnerDocument.sitestructure.destination + $parentElement.url
        Write-Host "Creating new web: $($parentElement.title)"
        Write-Verbose "New web url: $url"
        Write-Verbose "New web template: $($parentElement.template)"
        $web = New-SPWeb -Url $url -Template $parentElement.template -Name $parentElement.title
        Write-Host "Done!" -ForegroundColor Green
        $web.Title = $parentElement.title
        $web.Update()
    }else
    {
        Write-Error "Something went wrong. It looks like no site or web was given"
        Write-Error "$($parentElement.LocalName)"
    }

    #endregion

    #region Create Groups (site)
    Write-Host "Creating groups"
    if($parentElement.LocalName -eq "Site")
    {
        $xmlGroups = $parentElement.groups.group

        foreach($xmlGroup in $xmlGroups)
        {
               $defaultUser = Get-SPUser -Identity "fom\lcawkell_admin" -Web $web
            if([string]::IsNullOrEmpty(($owner = $web.SiteGroups[$xmlGroup.owner]))) # Check if the owner is a group first
            {
                try
                {
                    $owner = Get-SPUser -Identity $xmlGroup.owner.Substring($xmlGroup.owner.IndexOf("|")+1) -Web $web -ErrorAction Stop # If the owner is not a group then maybe a user?
                    $defaultUser = $owner
                }
                catch
                {
                    $owner = Get-SPUser -Identity "fom\lcawkell_admin" -Web $web # If the owner is not a group or user then something went wrong. It's probably a group that hasn't been created yet.
                }
            }

            $web.SiteGroups.Add($xmlGroup.name, $owner, $defaultUser, $xmlGroup.description)

            $group = $web.SiteGroups[$xmlGroup.name]

            foreach($xmlUser in $xmlGroup.user)
            {
                $user = New-SPUser -UserAlias $xmlUser.Substring($xmlUser.IndexOf("|")+1) -Web $web
                $group.AddUser($user)
            }
        }
    }

    #endregion

    #region Create Permissions

    $xmlPermissions = $parentElement.permissions

    if($xmlPermissions -ne $null)
    {
        Write-Host "Creating permissions"
        if($web.HasUniquePerm -eq $false)
        {
            $web.HasUniquePerm = $true
        }
    }

    $web.AnonymousState = 2 # TODO: Get this from xml file

    foreach($xmlAssignment in $xmlPermissions.assignment)
    {
        if([string]::IsNullOrEmpty(($user = $web.SiteGroups[$xmlAssignment.member]))) # Check if the owner is a group first
        {
            try
            {
                $user = Get-SPUser -Identity $xmlAssignment.member.Substring($xmlAssignment.member.IndexOf("|")+1) -Web $web -ErrorAction Stop # If the owner is not a group then maybe a user?

                if([string]::IsNullOrEmpty($user)) # If the user doesn't already exist somewhere on the web
                {
                    $user = New-SPUser -UserAlias $xmlAssignment.member.Substring($xmlAssignment.member.IndexOf("|")+1) -Web $web
                }
            }
            catch
            {
                Write-Error "Ran into a problem trying to get a user: $_"
            }
        }

        $assignment = New-Object Microsoft.SharePoint.SPRoleAssignment($user)

        foreach($xmlRole in $xmlAssignment.role)
        {
            if($xmlRole -ne "Limited Access")
            {
                $role = $web.RoleDefinitions[$xmlRole]
                $assignment.RoleDefinitionBindings.Add($role)
            }
        }

        $web.RoleAssignments.Add($assignment)

    }

    #endregion

    #region Create Libraries

    <#
     These two libraries are not available by default
     so these commands "ensure" they are available before 
     we try to add items to them.
    #>

    Write-Host "Creating libraries"
    $web.Lists.EnsureSiteAssetsLibrary() | Out-Null
    $web.Lists.EnsureSitePagesLibrary() | Out-Null

    foreach($xmlLibrary in $parentElement.library)
    {
        $libraryTitle = $xmlLibrary.Title

        try # Check if library already exists
        {
            $library = $web.Lists[$libraryTitle]

            if([string]::IsNullOrEmpty($library))
            {
                throw "Library Doesn't Exist!"
            }
        }
        catch # If it doesn't exist we need to create it first
        {
            try
            {
                $newWeb = $web.Lists.Add($libraryTitle, $libraryTitle, $xmlLibrary.template)
                $library = $web.Lists[$libraryTitle]
            }
            catch # Seems like the template is wrong (or something else)
            {
                Write-Debug "Cannot create the list with template type: $($xmlLibrary.template)"
                $newWeb = $web.Lists.Add($libraryTitle, $libraryTitle, "DocumentLibrary")
                $library = $web.Lists[$libraryTitle]
            }
        }

        # Set Library Settings

        $library.EnableModeration = ([bool]::Parse($xmlLibrary.enablemoderation))
        $library.EnableMinorVersions = ([bool]::Parse($xmlLibrary.enableminorversions))
        $library.EnableVersioning = ([bool]::Parse($xmlLibrary.enableversioning))
        $library.Update()

        foreach($xmlColumn in $xmlLibrary.fields.field)
        {
            if(([string]::IsNullOrEmpty($library.Fields[$xmlColumn.Name])) -and ([string]::IsNullOrEmpty($library.Fields[$xmlColumn.Title])))
            {
                $library.Fields.AddFieldAsXml($xmlColumn.InnerText)
            }
        }

        Add-SPFilesFromXml -xmlElement $xmlLibrary.folder -folder $library.RootFolder

        #region Add views
        Write-Host "Adding Views"
        if(($views = $xmlLibrary.views.view) -ne $null)
        {
            # Clear all current views (so we can add them back)
            $libraryViews = $library.Views
            $viewIDs = {}.Invoke()

         #   foreach($view in $libraryViews)
         #   {
         #       $viewIDs.Add($view.ID)
         #   }

         #   foreach($viewID in $viewIDs)
         #   {
         #       $library.Views.Delete($viewID)
         #   }

         #   foreach($xmlView in $xmlLibrary.views.view)
         #   {
         #   
         #       $xmlViewTitle = $xmlView.title
         #       $xmlViewFields = $xmlView.viewfields.Split(" ")
         #       $xmlViewQuery = $xmlView.query
         #       $xmlViewRowLimit = [int32]::Parse($xmlView.rowlimit)
         #       $xmlViewPaged = [bool]::Parse($xmlView.paged)
         #       $xmlViewMakeDefault = [bool]::Parse($xmlView.defaultview)
         #       $library.Views.Add($xmlViewTitle, $xmlViewFields, $xmlViewQuery, $xmlViewRowLimit, $xmlViewPaged, $xmlViewMakeDefault)

         #   } #end foreach
        } #end if
        #endregion
   # }

 #   foreach($xmlList in $parentElement.list)
#    {
 #       $xmlListTitle = $xmlList.title
#
 #        try # Check if library already exists
 #       {
 #           $list = $web.Lists[$xmlListTitle]
 #
 #           if([string]::IsNullOrEmpty($list))
 #           {
 #               throw "Library Doesn't Exist!"
 #           }
 #       }
 #       catch # If it doesn't exist we need to create it first
 #       {
 #           try
 #           {
 #               $newList = $web.Lists.Add($xmlListTitle, $xmlListTitle, $xmlList.template)
 #               $list = $web.Lists[$xmlListTitle]
 #           }
 #           catch # Seems like the template is wrong (or something else)
 #           {
 #               Write-Debug "Cannot create the list with template type: $($xmlList.template)"
 #               $newList = $web.Lists.Add($xmlListTitle, $xmlListTitle, "Custom List")
 #               $list = $web.Lists[$xmlListTitle]
 #           }
 #       }
#
 #       foreach($xmlColumn in $xmlList.fields.field)
 #       {
 #           if([string]::IsNullOrEmpty($list.Fields[$xmlColumn.Title]))
 #           {
 #               $list.Fields.AddFieldAsXml($xmlColumn.InnerText)
 #           }
 #       }
 #       $listItemIndex = 1
 #       foreach($listItem in $xmlList.items.item)
 #       {
 #           Write-Verbose "Creating new list item $($listItem.Title) in $list $listItemIndex\$($xmlList.items.item.count)"
 #           $newItem = $list.Items.Add()
 #           Write-Verbose "Done creating list item.. Adding fields"
 #           $fieldIndex = 1
 #           foreach($itemField in $listItem.itemfield)
 #           {
 #               try
 #               {
 #                   Write-Verbose "Adding new field $($itemField.title) $fieldIndex\$($listItem.itemfield.count) in $list"
 #                   $newField = ($newItem[$itemField.title] = $itemField.innertext)
 #                   $newItem.Update()
 #                   Write-Verbose "New Field added! $($newItem[$itemField.title])"
 #               }
 #               catch
 #               {
 #                   Write-Debug "Could not add new field"
 #                   Write-Error $_
 #               }
 #               $fieldIndex++
 #           }
 #           $listItemIndex++
            
 #       }

        #region Add views
 #       Write-Host "Adding Views"
 #       if(($views = $xmlList.views.view) -ne $null)
 #       {
 #           # Clear all current views (so we can add them back)
 #           $listViews = $list.Views
 #           $viewIDs = {}.Invoke()
 #
 #           foreach($view in $listViews)
 #           {
 #               $viewIDs.Add($view.ID)
 #           }
 #
 #           foreach($viewID in $viewIDs)
 #           {
 #               $list.Views.Delete($viewID)
 #           }
 #
 #           foreach($xmlView in $xmlList.views.view)
 #           {
 #           
 #               $xmlViewTitle = $xmlView.title
 #               $xmlViewFields = $xmlView.viewfields.Split(" ")
 #               $xmlViewQuery = $xmlView.query
 #               $xmlViewRowLimit = [int32]::Parse($xmlView.rowlimit)
 #               $xmlViewPaged = [bool]::Parse($xmlView.paged)
 #               $xmlViewMakeDefault = [bool]::Parse($xmlView.defaultview)
 #               $list.Views.Add($xmlViewTitle, $xmlViewFields, $xmlViewQuery, $xmlViewRowLimit, $xmlViewPaged, $xmlViewMakeDefault)
 #
 #           } #end foreach
 #       } #end if
        #endregion
        


    }

 

    #endregion

    #region Create Navigation Settings
    Write-Host "Updating navigation"
    $publishingWeb = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($web)

    $pubWebNavigation = $publishingWeb.Navigation
        
    $pubWebNavigation.InheritGlobal = [System.Convert]::ToBoolean($parentElement.navigation.inheritglobal)
    $pubWebNavigation.InheritCurrent = [System.Convert]::ToBoolean($parentElement.navigation.inheritcurrent)
    $pubWebNavigation.GlobalIncludeSubSites = [System.Convert]::ToBoolean($parentElement.navigation.globalincludesubsites)
    $pubWebNavigation.GlobalIncludePages = [System.Convert]::ToBoolean($parentElement.navigation.globalincludepages)
    $pubWebNavigation.ShowSiblings = [System.Convert]::ToBoolean($parentElement.navigation.currentshowsiblings)
    $pubWebNavigation.CurrentIncludeSubSites = [System.Convert]::ToBoolean($parentElement.navigation.currentincludesubsites)
    $pubWebNavigation.CurrentIncludePages = [System.Convert]::ToBoolean($parentElement.navigation.currentincludepages)
    $pubWebNavigation.OrderingMethod = "Automatic"
    $pubWebNavigation.AutomaticSortingMethod = "CreatedDate"
    

    $pubWebNavigationNodes = $pubWebNavigation.CurrentNavigationNodes
    
    $CreateSPNavigationNode = [Microsoft.SharePoint.Publishing.Navigation.SPNavigationSiteMapNode]::CreateSPNavigationNode


    foreach($node in $parentElement.navigation.node)
    {
        $headingNode = $CreateSPNavigationNode.Invoke($node.title, $node.url, [Microsoft.SharePoint.Publishing.NodeTypes]::Heading, $pubWebNavigationNodes)


    }


    $publishingWeb.Update()

    $web.CustomMasterUrl = "$($web.Site.RootWeb.ServerRelativeUrl)/_catalogs/masterpage/MedNetPublishing.master"
    $web.MasterUrl = "$($web.Site.RootWeb.ServerRelativeUrl)/_catalogs/masterpage/MedNetPublishing.master"
    $web.AllProperties["__InheritsCustomMasterUrl"] = "True"
    $web.AllProperties["__InheritsMasterUrl"] = "True"
    $web.Update()
    
    #endregion

    #region Recursively do it all again

    foreach($xmlWeb in $parentElement.web)
    {
        New-SPWebFromXml -parentElement $xmlWeb
    }

    #endregion



   # $web.Dispose()
   # $site.Dispose()

}

function Sync-SPBrandingFiles
{
    Param(
    [string]$inputDirectory,
    [Microsoft.SharePoint.SPSite]$site
    )

    $web = $site.OpenWeb()

    $masterPageGallery = $web.GetFolder("_catalogs/masterpage/")
    $templatesFolder = $web.GetFolder("_catalogs/masterpage/Display Templates/Content Web Parts")
    $StyleLibrary = $web.GetFolder("Style Library/XSL Style Sheets")


    try
    {
        $masterpages = Get-ChildItem "$inputDirectory\masterpage\*.master"
        $layouts = Get-ChildItem "$inputDirectory\layouts\*.html"
        $templates = Get-ChildItem "$inputDirectory\templates\*.html"
        $xslSheets = Get-ChildItem "$inputDirectory\xsl\*.xsl"
    }catch
    {
        Write-Host "Error: $_" -ForegroundColor Red
    }


    foreach($file in $masterpages)
    {
        try
        {

            $masterpage = $masterPageGallery.Files.Add($file.Name, $file.OpenRead(), $true)
            $masterpage.Publish("Published during migration")
        }
        catch
        {
            Write-Host "Error : $_" -foregroundcolor Red
        }
    }

    foreach($file in $layouts)
    {
        try
        {
            $layout = $masterPageGallery.Files.Add($file.Name, $file.OpenRead())
            $layout.Properties["vti_title"] = $layout.Title
            $layout.Update()
            $layout.Publish("Published during migration")
            $layout.Update()
        }
        catch
        {
            Write-Host "Error : $_" -foregroundcolor Red
        }
    }

    foreach($file in $templates)
    {
        try
        {
            $template = $templatesFolder.Files.Add($file.Name, $file.OpenRead())
            Start-Sleep -Seconds 3
            $template.Update()
            $template.Publish("Published during migration")
            $template.Update()
        }
        catch
        {
            Write-Host "Error : $_" -foregroundcolor Red
        }
    }

    foreach($file in $xslSheets)
    {
        try
        {
            $xslSheet = $StyleLibrary.Files.Add($file.Name, $file.OpenRead())
            Write-Debug "Trying to check in xsl stylesheet"
            $xmlSheet.CheckIn()
            $xmlSheet.Publish("Published during migration")
        }
        catch
        {
            Write-Host "Error : $_" -foregroundcolor Red
        }
    }

}

function Add-SPFilesFromXml
{
Param(
[System.Xml.XmlElement]$xmlElement,
[Microsoft.SharePoint.SPFolder]$folder
)

    $files = $folder.Files
    $list = $folder.DocumentLibrary

    foreach($xmlFile in $xmlElement.file)
    {
        try
        {
            $files[$xmlFile.name].CheckOut()
               
        }catch
        {
            Write-Verbose "$($xmlFile.name) does not already exist on the site. No checkout performed."
        }

        $file = Get-ChildItem -Path $xmlFile.path

        try
        {
            $newFile = $files.Add($xmlElement.urlname + "/" + $xmlFile.name, $file.OpenRead(), $true)
        }
        catch
        {
            Write-Debug $_
        }

        try
        {
            foreach($xmlField in $xmlFile.itemField)
            {
                $newFile.Item[$xmlField.title] = $xmlField.InnerText
            }
        }catch
        {
            Write-Debug -Message $_
        }

        #$newFile.Update()
        #$newFile.CheckIn("Checked in automatically during migration")
        #$newFile.Publish("Published automatically during migration")

        Write-Debug "Setting layouts based on previous layouts"

        if($xmlElement.ParentNode.title -eq "Pages")
        {
            if($newFile.CheckOutType -eq "None")
            {
                $newFile.CheckOut()
            
            }
            if($newFile.Properties["PublishingPageLayout"] -eq "http://test.mednet.med.ubc.ca/_catalogs/masterpage/ubcfom_homelayout.aspx, UBC FOM Home Page Layout" -or
               $newFile.Properties["PublishingPageLayout"] -eq "https://test.mednet.med.ubc.ca/_catalogs/masterpage/ubcfom_homelayout.aspx, UBC FOM Home Page Layout")
            {
                $newFile.Properties["PublishingPageLayout"] = "$($folder.ParentWeb.Site.url)/_catalogs/masterpage/HomePageLayout.aspx, HomePage"

                $newFile.Update()
            }
            elseif ($newFile.Properties["PublishingPageLayout"] -eq "http://test.mednet.med.ubc.ca/_catalogs/masterpage/ubcfom_inner_1col.aspx, ubcfom_inner_1col" -or
                    $newFile.Properties["PublishingPageLayout"] -eq "https://test.mednet.med.ubc.ca/_catalogs/masterpage/ubcfom_inner_1col.aspx, ubcfom_inner_1col")
            {
                $newFile.Properties["PublishingPageLayout"] = "$($folder.ParentWeb.Site.url)/_catalogs/masterpage/OneColumn.aspx, One Column"
                $newFile.Update()
            }
            elseif ($newFile.Properties["PublishingPageLayout"] -eq "http://test.mednet.med.ubc.ca/_catalogs/masterpage/ubcfom_inner_1col.aspx, UBC FOM 1 Column Inner Page Layout" -or
                    $newFile.Properties["PublishingPageLayout"] -eq "https://test.mednet.med.ubc.ca/_catalogs/masterpage/ubcfom_inner_1col.aspx, UBC FOM 1 Column Inner Page Layout")
            {
                $newFile.Properties["PublishingPageLayout"] = "$($folder.ParentWeb.Site.url)/_catalogs/masterpage/OneColumn.aspx, One Column"
                $newFile.Update()
            }
            elseif ($newFile.Properties["PublishingPageLayout"] -eq "https://test.mednet.med.ubc.ca/sites/intranetng201/_catalogs/masterpage/OneColumn.aspx, One Column" -or
                    $newFile.Properties["PublishingPageLayout"] -eq "http://test.mednet.med.ubc.ca/sites/intranetng201/_catalogs/masterpage/OneColumn.aspx, One Column")
            {
                $newFile.Properties["PublishingPageLayout"] = "$($folder.ParentWeb.Site.url)/_catalogs/masterpage/OneColumn.aspx, One Column"
                $newFile.Update()
            }
            elseif ($newFile.Properties["PublishingPageLayout"] -eq "http://test.mednet.med.ubc.ca/_catalogs/masterpage/ubcfom_inner_2col.aspx, UBC FOM 2 Column Inner Page Layout" -or
                    $newFile.Properties["PublishingPageLayout"] -eq "https://test.mednet.med.ubc.ca/_catalogs/masterpage/ubcfom_inner_2col.aspx, UBC FOM 2 Column Inner Page Layout")
            {
                $newFile.Properties["PublishingPageLayout"] = "$($folder.ParentWeb.Site.url)/_catalogs/masterpage/TwoColumn.aspx, Two Column"
                $newFile.Update()
            }
            elseif ($newFile.Properties["PublishingPageLayout"] -eq "https://test.mednet.med.ubc.ca/sites/intranetng201/_catalogs/masterpage/TwoColumn.aspx, Two Column" -or
                    $newFile.Properties["PublishingPageLayout"] -eq "http://test.mednet.med.ubc.ca/sites/intranetng201/_catalogs/masterpage/TwoColumn.aspx, Two Column")
            {
                $newFile.Properties["PublishingPageLayout"] = "$($folder.ParentWeb.Site.url)/_catalogs/masterpage/TwoColumn.aspx, Two Column"
                $newFile.Update()
            }
            else
            {
                $newFile.Properties["PublishingPageLayout"] = "$($folder.ParentWeb.Site.url)/_catalogs/masterpage/ArticleLeft.aspx, ArticleLeft"
                $newFile.Update()
            }
            
        }

        try
        {
            if($newFile.CheckOutType -ne "None")
            {
                $newFile.CheckIn("Automatically checked in during migration",[Microsoft.SharePoint.SPCheckinType]::MajorCheckIn)
            
            }
        }catch
        {
            Write-Debug "File: $newFile does not need to be checked in."
        }

        #Publishing the item
        if( $list.EnableVersioning -and $list.EnableMinorVersions) 
        {   
            $newFile.Publish("Published automatically during migration")  
        }  

        #Approving it in case approval is required
        if($list.EnableModeration)
        {
            $newFile.Approve("Approved automatically during migration")
        }
    }
    

    foreach($xmlSubFolder in $xmlElement.folder)
    {
        try
        {
            $subfolder = $folder.SubFolders[$xmlSubFolder.name]
        }
        catch
        {
            Write-Debug $_
        }

        if($subfolder -eq $null)
        {
            $urlName = $xmlSubFolder.name
            $folder.SubFolders.Add($folder.Url + "/" + $urlName)
            $subfolder = $folder.SubFolders[$urlName]
        }

        Add-SPFilesFromXml -xmlElement $xmlSubFolder -folder $subfolder
    }

}

function New-SPSiteToXmlInput
{
Param
(
[string]$path,
[Microsoft.SharePoint.SPSite]$site
)

$xmlDocument = New-Object Xml

$xmlInput = $xmlDocument.CreateElement("input")

$xmlDocument.AppendChild($xmlInput) | Out-Null

$xmlReorganize = $xmlDocument.CreateElement("reorganize")

$xmlInput.AppendChild($xmlReorganize) | Out-Null

$xmlSite = $xmlDocument.CreateElement("site")

$xmlSite.SetAttribute("title", $site.RootWeb.Title)

$xmlReorganize.AppendChild($xmlSite) | Out-Null

foreach($web in $site.RootWeb.Webs)
{
    New-SPWebToXmlInput -parentElement $xmlSite -web $web
}

$xmlDocument.Save($path)

}

function New-SPWebToXmlInput
{
Param
(
[System.Xml.XmlElement]$parentElement,
[Microsoft.SharePoint.SPWeb]$web
)

$xmlDocument = $parentElement.OwnerDocument

$xmlWeb = $xmlDocument.CreateElement("web")

$xmlWeb.SetAttribute("title", $web.Title)
$xmlWeb.SetAttribute("names", $web.Name)

$parentElement.AppendChild($xmlWeb) | Out-Null

foreach($subweb in $web.webs)
{
    New-SPWebToXmlInput -parentElement $xmlWeb -web $subweb
}

}