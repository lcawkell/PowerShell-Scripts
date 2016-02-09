[System.Reflection.Assembly]::LoadWithPartialName("System")  | out-null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")  | out-null
[System.Reflection.Assembly]::LoadWithPartialName("System.Collections.Generic")  | out-null
[System.Reflection.Assembly]::LoadWithPartialName("System.Xml")  | out-null

function SetLogFile()
{
	$logtimestamp = Get-Date -Format "ddMMyymmss"
	$script:logfile = Get-ScriptDirectory
    $script:logfile = (Combine $script:logfile ("SCRIPTLOG-" + $logtimestamp + ".txt"))
}
	
function LogEvents([string] $message, [string] $logtype)
{
	$eventtimestamp = Get-Date -Format "u" 
	[string]$output = ""

	if ((Test-Path $script:$logfile) -eq $false)
	{
		# The logfile doesn't exist yet, so we need to create it
		"Timestamp,Logtype,Event" | Out-File $script:$logfile -Encoding ASCII
	}		
    $output = $eventtimestamp + ", " + $logtype + "," + $message 
    $output | Out-File $script:$logfile -Append -Encoding ASCII

	$output = $eventtimestamp + " :: " + $message
	switch ($logtype)
	{
		"Event"	{
			Write-Host $output -ForegroundColor White -BackgroundColor Blue
		}
		"Warning"	{
			Write-Host $output -ForegroundColor DarkRed -BackgroundColor Yellow
		}
		"Error"		{
			Write-Host $output -ForegroundColor White -BackgroundColor DarkRed
		}
		default		{
			Write-Host $output						
		}
	}
}
    
function loadSnapins 
{
    $snap = get-pssnapin | where {$_.Name -eq "Microsoft.SharePoint.PowerShell" }
    if($snap -ne $null) 
    {
        LogEvents "Reloading SharePoint Snapin" "Message" 
        Remove-PSSnapin Microsoft.SharePoint.PowerShell
    } else {
        LogEvents "Loading SharePoint Snapin" "Message" 
    }    
    $snap = Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue -PassThru;
    #$snap = get-pssnapin | where {$_.Name -eq "Microsoft.SharePoint.PowerShell" }
    if($snap -eq $null) 
    {
        LogEvents "Could not load SharePoint Snapin" "Warning" 
    }        
}

function get-webpagetimeout([string]$url,[System.Net.NetworkCredential]$cred=$null)
	{
	LogEvents "Warming up site at:",$url "Message" 
	$wc = [System.Net.WebRequest]::Create($url)
	$wc.Timeout = 600000
	if($cred -eq $null)
		{
		$cred = [System.Net.CredentialCache]::DefaultCredentials;
		}
	$wc.Credentials = $cred;
	$response = $wc.GetResponse()
	$sr = New-Object System.IO.StreamReader($response.GetResponseStream())
	return $sr.ReadToEnd()
	}
	
function get-webpage([string]$url,[System.Net.NetworkCredential]$cred=$null)
	{
	$wc = new-object net.webclient
	if($cred -eq $null)
		{
		$cred = [System.Net.CredentialCache]::DefaultCredentials;
		}
	$wc.credentials = $cred;
	return $wc.DownloadString($url);
	}
    
function checkAccountAndGetAppPool([string] $apppoolName, [string] $login, [string] $password)
{

  LogEvents "Retrieving the managed account:",$login "Message" 
  $securePassword = (ConvertTo-SecureString $password -AsPlainText -force)
  $ManagedAccountGen = Get-SPManagedAccount | Where-Object {$_.UserName -eq $login}
  if ($ManagedAccountGen -eq $NULL) 
  { 
    LogEvents "Registering managed account" "Message" 
    $cred_AppPoolAcct = New-Object System.Management.Automation.PsCredential $login, $securePassword
    $ManagedAccountGen = New-SPManagedAccount -Credential $cred_AppPoolAcct
  }
  else
  {
    LogEvents "Managed account already exists" "Message" 
  }
    
  ## App Pool
  LogEvents "Getting Application Pool, creating if necessary..." "Message" 
  $ApplicationPool = Get-SPServiceApplicationPool $apppoolName -ea SilentlyContinue
  if($ApplicationPool -eq $null)
  { 
    $ApplicationPool = New-SPServiceApplicationPool $apppoolName -account $ManagedAccountGen
    if (-not $?)
    {
        LogEvents "Failed to create application pool" "Message" 
        throw "Failed to create an application pool"
    }
  }

  return $ApplicationPool

}    
	
function ApproveFolderOrItem($folderoritem)
{
    # If someone unpublished the version or checked out, the item goes in draft mode
    $modInfo = $folderoritem.Item.ModerationInformation
    
    # If publishing status is draft then publish with major version Folder's wont go in 'Draft mode'
    if($modInfo.Status -eq [Microsoft.SharePoint.SPModerationStatusType]::Draft)
    {
		LogEvents "Item is in draft state, so publishing first..." "Message" 
        $folderoritem.Publish("Uploaded by bulk test uploader")
    }
    
    # Get the moderation information again as page goes from draft to pending approval
    $modInfo = $folderoritem.Item.ModerationInformation
    
    if($modInfo.Status -eq [Microsoft.SharePoint.SPModerationStatusType]::Pending)
    {
        if(($ApproveFolders -eq "true") -and ($folderoritem.GetType() -eq [Microsoft.SharePoint.SPFolder]))
        {
			LogEvents "Approving folder:",$folderoritem.Name," with a current status of Pending" "Message" 
            # Its a folder we need to approve it in different way ;)
            $folderoritem.Item.ModerationInformation.Status = [Microsoft.SharePoint.SPModerationStatusType]::Approved
            $folderoritem.Item.ModerationInformation.Comment = "Approved by bulk test uploader"
            $folderoritem.Item.Update()
        }
        else
        {
            # Its a file
			LogEvents "Approving item:",$folderoritem.Name," with a current status of Pending" "Message" 
            $folderoritem.Approve("Approved by bulk test uploader")
        }
    }
}

function CreateFolder($splist, $folder)
{
	# Perform a split on the folders
	$spfolder = $null
	if ($splist.EnableFolderCreation)
	{
		if (![String]::IsNullOrEmpty($folder))
		{
			if($folder -eq "/")
			{
				$spfolder = $splist.RootFolder
			}
			else
			{
				$pathstructure = $folder.Split("/")
				$arraylength = $pathstructure.Length - 1
				$newfoldername = $splist.ParentWeb.Url + "/" + $splist.RootFolder.Url
				$parentfoldername = $newfoldername
				for ($foldercount = 0; $foldercount -le $arraylength; $foldercount++)
				{
					$newfoldername = $newfoldername + "/" + $pathstructure[$foldercount]
					$spnewfolder = $splist.ParentWeb.GetFolder($newfoldername)
					if (-not $spnewfolder.Exists)
					{
						LogEvents "Adding new sub-folder at:",$newfoldername "Message" 
						$spnewfolder = $splist.ParentWeb.GetFolder($parentfoldername).SubFolders.Add($newfoldername)
						if (-not $spnewfolder.Exists)
						{
							# We probably don't want to continue if we can't create the folder structure so
							# some investigation (likely security) will be required
							LogEvents "Unable to add sub-folder at:",$newfoldername "Warning" 
							break
						}
						else
						{
							# Only need to do if content approval is enabled
							ApproveFolderOrItem $spnewfolder
							$spfolder = $spnewfolder
							$parentfoldername = $newfoldername
						}
					}
				}
			}
		}
		else
		{
			$spfolder = $splist.RootFolder
		}
	}
	else
	{
		$spfolder = $splist.RootFolder
	}
	return $spfolder
}

function deploy-features([string] $targeturl, [string] $wsppath)
{
	$waittimeinseconds = 30
	$searchpath = $wsppath + "\*.wsp"
	LogEvents "WSP Search Path Specified:",$searchpath "Message" 
	$webapp = Get-SPWebApplication $targeturl
	LogEvents "Retrieved web application at:",$webapp "Message" 
	
	Get-ChildItem $searchpath | foreach {
		$solution = $null
		$solutionname = $_.Name
		$solutionpath = $wsppath + "\" + $solutionname
		LogEvents "Adding solution:",$solutionname "Message" 
		Get-SPSolution | foreach {
			if ($_.Name -eq $solutionname)
			{
				LogEvents "Found solution:",$solutionname "Message" 
				$solution = $_
			}
		}
		if ($solution -ne $null)
		{
			if (!$solution.Deployed)
			{
				LogEvents "Solution deployed, Uninstalling",$solutionname "Warning" 
				try
				{
				    if ($solution.DeployedWebApplications -eq $null)
				    {
                        LogEvents "Uninstall with no web application resources...",$solutionname "Message" 
                        try
                        {
                            Uninstall-SPSolution -Identity $solutionname -Confirm:$false
                        }
                        catch
                        {
                            LogEvents "Unable to uninstall solution (no web app resources):",$solutionname," Error:",$_.Exception.Message "Warning" 	
                        }
				    }
				    else
				    {
                        LogEvents "Uninstall for all web applications",$solutionname "Message" 
                        try
                        {					
                            Uninstall-SPSolution -Identity $solutionname -AllWebApplications -Confirm:$false
                        }
                        catch
	   		      		{
    						LogEvents "Unable to uninstall solution (no web app resources):",$solutionname," Error:",$_.Exception.Message "Warning" 	
                        }					
                    }
			    }
				catch
				{
					LogEvents "Unable to uninstall solution:",$solutionname," Error:",$_.Exception.Message "Warning" 
				}					
				Write-Host "Waiting for solution uninstall" -NoNewline -ForegroundColor Cyan
				$sleepcount = 0
				$bstop = $false
				do {
					Start-Sleep -s 1
					$sleepcount++
					Write-Host "." -NoNewline -ForegroundColor Cyan
					if ($sleepcount -gt $waittimeinseconds)
					{
						$bstop = $true
					}
					if ($newsolution.Deployed)
					{
						$bstop = $true
					}
				} while ( -not $bstop )
				Write-Host ""
			}
			LogEvents "Removing existing solution:",$solutionname "Event" 
			Remove-SPSolution -Identity $solutionname -Force -Confirm:$false
		}
		LogEvents "Adding solution:",$solutionname "Message" 
		$newsolution = Add-SPSolution -LiteralPath $solutionpath
		if ($newsolution -ne $null)
		{
			if ($newsolution.ContainsWebApplicationResource)
			{
				LogEvents "Installing solution with web application scope:",$solutionname "Event" 
				Install-SPSolution -Identity $solutionname -WebApplication $webapp -GACDeployment -Force:$true
			}
			else
			{
				LogEvents "Installing solution:",$solutionname "Event" 
				Install-SPSolution -Identity $solutionname -GACDeployment -Force:$true
			}
			Write-Host "Waiting for solution to deploy" -NoNewline -ForegroundColor Cyan
			$sleepcount = 0
			$bstop = $false			
			do {
				Start-Sleep -s 1
				$sleepcount++
				Write-Host "." -NoNewline -ForegroundColor Cyan
				if ($sleepcount -gt $waittimeinseconds)
				{
					$bstop = $true
				}
				if ($newsolution.Deployed)
				{
					$bstop = $true
				}
			} while ( -not $bstop )
			Write-Host ""
		}
		$solution = Get-SPSolution -Identity $solutionname
		if ($solution -ne $null)
		{
			LogEvents "Solution installed:",$_.Name "Event" 
		}
	}
}

function group-wsps([string] $parentpath, [string] $targetpath)
{
	LogEvents "WSP Build Path Specified:",$searchpath "Event" 
	Get-ChildItem $parentpath -Recurse | where {$_.Extension -eq ".wsp" } | foreach {
		LogEvents "Copying:",$_.Name,"to:",$targetpath "Message" 
		$_.CopyTo($targetpath + "\" + $_.Name, $true)
		}
}

function wait-foractivation([string] $featureid, [string] $targeturl)
{
	$feat = Get-SPFeature -Identity $featureid
	
	if ($feat -ne $null)
	{
		if ($feat.Scope.ToString() -eq "Web")
		{
			$web = Get-SPWeb -Identity $targeturl
			if ($web -ne $null)
			{
				Write-Host "Waiting for feature to activate..." -NoNewline -ForegroundColor Cyan
				do {
					Start-Sleep -s 1
					Write-Host "." -NoNewline -ForegroundColor Cyan
				} while ( $web.Features[$featureid] -eq $null )
				Write-Host ""
			}
		}
		elseif ($feat.Scope.ToString() -eq "Site")
		{
			$site = Get-SPSite -Identity $targeturl
			if ($site -ne $null)
			{
				Write-Host "Waiting for feature to activate..." -NoNewline -ForegroundColor Cyan
				do {
					Start-Sleep -s 1
					Write-Host "." -NoNewline -ForegroundColor Cyan
				} while ( $site.Features[$featureid] -eq $null )
				Write-Host ""
			}
		}
		elseif ($feat.Scope.ToString() -eq "WebApplication")
		{
			$webapp = Get-SPWebApplication -Identity $targeturl
			if ($webapp -ne $null)
			{
				Write-Host "Waiting for feature to activate..." -NoNewline -ForegroundColor Cyan
				do {
					Start-Sleep -s 1
					Write-Host "." -NoNewline -ForegroundColor Cyan
				} while ( $webapp.Features[$featureid] -eq $null )
				Write-Host ""
			}
		}
	}
}


# Activates a target feature at the specified URL, optionally resetting IIS at the same time
function ActivateFeature([string] $featureguid, [string] $targeturl, [string] $featuredescription, [bool] $resetiis, [bool] $warmupsite)
{
	[bool]$success = $false
	if (![String]::IsNullOrEmpty($featureguid))
	{
		if (![String]::IsNullOrEmpty($targeturl))
		{
			try
			{
				if (![String]::IsNullOrEmpty($featuredescription))
				{
					LogEvents $featuredescription "Event" 
				}
				else
				{
					LogEvents "Activating feature:",$featureguid "Event" 
				}
				Enable-SPFeature -Identity $featureguid -url $targeturl
				wait-foractivation $featureguid $targeturl
				$success = $true
			}
			catch
			{
					LogEvents "Unable to activatefeature:",$featureguid," Error:",$_.Exception.Message "Warning" 
			}
			if ($resetiis)
			{
				LogEvents "Performing IISReset" "Message" 
				start-process "iisreset" -Wait -WindowStyle:Hidden
				if ($warmupsite)
				{
					LogEvents "Warming up site..." "Message" 
					$html=get-webpagetimeout -url $targeturl -cred $cred
				}
			}
		}
	}
	return $success
}

# Adds a subsite and the specified relative path.  The relative paths
# are important for the activation of features that are scoped to web's rather than
# sites.  Returns a web for subsequent operations if necessary.  The subweb path should start with a slash
function AddSubSite([string] $targetsite, [string]$subwebpath, [string]$template, [string] $description, [string] $title, [bool] $activatepublishing)
{
	$newweb = $null
	if (![String]::IsNullOrEmpty($targetsite))
	{
		if (![String]::IsNullOrEmpty($subwebpath))
		{
			$targeturl = $targetsite + $subwebpath
			try
			{
				$newweb = New-SPWeb -Url $targeturl -Template $template -Name $title `
					-Description $description -AddToQuickLaunch:$false `
					-UniquePermissions:$false -AddToTopNav:$false `
					-UseParentTopNav:$true
			}
			catch
			{
				LogEvents "Unable to create subsite at:",$targeturl," Error:",$_.Exception.Message "Warning" 
			}
			if ($newweb -ne $null)
			{
				if ($activatepublishing)
				{
					ActivateFeature "99fe402e-89a0-45aa-9163-85342e865dc8" $targeturl "Loading standard web features" $false $false
					ActivateFeature "94c94ca6-b32f-4da9-a9e3-1f3d343d7ecb" $targeturl "Loading publishing web features" $false $false
				}
			}
		}
	}
	return $newweb
}

function Get-ScriptDirectory
{
	$Invocation = (Get-Variable MyInvocation).Value
	$sd =  Split-Path $Invocation.ScriptName
	return $sd
}

Function Combine([string]$path1, [string]$path2)
{
  return [System.IO.Path]::Combine($path1, $path2)
}

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
    $collection = $pweb.Navigation.GlobalNavigationNodes
 
    # get current nodes
    $globalNavSettings = New-Object System.Configuration.ProviderSettings("GlobalNavSiteMapProvider", "Microsoft.SharePoint.Publishing.Navigation.PortalSiteMapProvider, Microsoft.SharePoint.Publishing, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c")
    $globalNavSettings.Parameters["NavigationType"] = "Global"
    $globalNavSettings.Parameters["EncodeOutput"] = "true"
    [Microsoft.SharePoint.Publishing.Navigation.PortalSiteMapProvider] $globalNavSiteMapProvider = [System.Web.Configuration.ProvidersHelper]::InstantiateProvider($globalNavSettings, [type]"Microsoft.SharePoint.Publishing.Navigation.PortalSiteMapProvider")
    [Microsoft.SharePoint.Publishing.Navigation.PortalSiteMapNode] $currentNode = $globalNavSiteMapProvider.CurrentNode
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
    return [Microsoft.SharePoint.Publishing.Navigation.SPNavigationSiteMapNode]::UpdateSPNavigationNode($node, $null, $name, $node.Url, $description, $target, $audience, $false)
}

#Marcus: 
# E.g. unDeclareRecords "http://sp2010-mb:9909/sites/t4/" "Team Documents"
#Description: Undeclares an item in a list as a record
function unDeclareRecords([string] $siteUrl, [string] $listName) {
    $mySite = Get-SPSite($siteUrl)
    $myWeb = $mySite.rootweb;
    $myList = $myWeb.Lists[$listName]
     foreach ($item in $myList.Items)
     {
        if([Microsoft.Office.RecordsManagement.RecordsRepository.Records]::IsRecord($item) -ne $false)
       {
            Write-Host $item.Name + "\n"
            Write-Host "   - is a record. Undeclaring..."
            [Microsoft.Office.RecordsManagement.RecordsRepository.Records]::UndeclareItemAsRecord($item)
        }
        else {
            Write-Host $item.Name + "\n"
            Write-Host "   - is not a record"
        }
     }
 }
 
#Miguel Tena
# Creates a new page on a defined subweb with the determined page layout.
# i.e. CreateNewPage "http://fomvss221t4" "/AboutUs/OurOrganization" "TestPage.aspx" "My Test Page" "My Own Description" "Blank Web Part page"

function CreateNewPage([string] $targetsite, [string]$subwebpath, [string]$pageFileName, [string] $pagetitle, [string] $description , [string] $pageLayoutName)
{
$spWeb = Get-SPWeb $subwebpath -site $targetsite 
  if($spWeb -ne $null)
  { 
  $pubWeb = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($spWeb)

  $pageLayout = $pubWeb.GetAvailablePageLayouts() | Where-Object {$_.Title -eq $pageLayoutName}

  $page = $pubWeb.GetPublishingPages().Add($pageFileName, $pageLayout)

  $page.Title = $pagetitle
  $pageItem = $page.ListItem
  $pageItem["Comments"]="New page description"
  $page.Update()

  $page.CheckIn("Checked in by PowerShell script")
  $page.listItem.File.Publish("Published by PowerShell script")
  }
$spWeb.Dispose()
} 

function New-SPGroup {
<#
.Synopsis
	Use New-SPGroup to create a SharePoint Group.
.Description
	This function uses the Add() method of a SharePoint RoleAssignments property in an SPWeb to create a SharePoint Group.
.Example
	C:\PS>New-SPGroup -Web http://intranet -GroupName "Test Group" -OwnerName DOMAIN\User -MemberName DOMAIN\User2 -Description "My Group"
	This example creates a group called "Test Group" in the http://intranet site, with a description of "My Group".  The owner is DOMAIN\User and the first member of the group is DOMAIN\User2.
.Notes
	Name: New-SPGroup
	Author: Ryan Dennis
	Last Edit: July 18th 2011
	Keywords: New-SPGroup
.Link
	http://www.sharepointryan.com
 	http://twitter.com/SharePointRyan
.Inputs
	None
.Outputs
	None
#Requires -Version 2.0
#>
	[CmdletBinding()]
	Param(
	[Microsoft.SharePoint.PowerShell.SPWebPipeBind]$Web,
	[string]$GroupName,
	[string]$OwnerName,
	[string]$MemberName,
	[string]$Description
	)
	$SPWeb = $Web.Read()
	if ($SPWeb.SiteGroups[$GroupName] -ne $null){
		# throw "Group $GroupName already exists!"	
		LogEvents "Group $GroupName already exists!" "Warning" 
	}
	else
	{
		if ($SPWeb.Site.WebApplication.UseClaimsAuthentication){
			$op = New-SPClaimsPrincipal $OwnerName -IdentityType WindowsSamAccountName
			$mp = New-SPClaimsPrincipal $MemberName -IdentityType WindowsSamAccountName
			$owner = $SPWeb | Get-SPUser $op
			$member = $SPWeb | Get-SPUser $mp
		}
		else {
		$owner = $SPWeb | Get-SPUser $OwnerName
		$member = $SPWeb | Get-SPUser $MemberName
		}
	
		$SPWeb.SiteGroups.Add($GroupName, $owner, $member, $Description)
	}
	$SPGroup = $SPWeb.SiteGroups[$GroupName]
	$SPWeb.RoleAssignments.Add($SPGroup)
	$SPWeb.Dispose()
	return $SPGroup
}

#Clears Quick Launch navigation and sets navigation depending the level

#Samples

#ConfigureNav $rootSiteUrl "ServicesAndResources" "Level1" $true $true

#ConfigureNav $rootSiteUrl "AboutUs/OurPeople" "Level2" $true $true

#ConfigureNav $rootSiteUrl "ServicesAndResources/Communications/EventPromotion" "Level3" $true $true

function ConfigureNav([string] $targetsite, [string]$subwebpath, [string]$level, [bool] $includeSubsites, [bool] $includePages)
{
$spWeb = Get-SPWeb $subwebpath -site $targetsite 
  if($spWeb -ne $null)
    {

    $qlNav = $spWeb.Navigation.QuickLaunch
    $currentLinks = @()
    
    #Clear Quick Launch links
    $qlNav | ForEach-Object {
    $currentLinks = $currentLinks + $_.Id
    }
    $currentLinks | ForEach-Object {
    $currentNode = $spWeb.Navigation.GetNodeById($_)
    write-host "Deleting" $currentNode.Title " Heading and all child navigation links..."
    $qlNav.Delete($currentNode)
    }

    $mywebpub = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($spWeb)

    $mywebpub.Navigation.CurrentIncludeSubSites = $includeSubsites
    $mywebpub.Navigation.CurrentIncludePages = $includePages

    if($level -eq "Level1")
    {
    #Show only items below the current site
        $mywebpub.InheritCurrentNavigation = $false;
        $mywebpub.NavigationShowSiblings = $false;
    }
    elseif ($level -eq "Level2")
    {
    #Show siblings and items below the current site
        $mywebpub.InheritCurrentNavigation = $false;
        $mywebpub.NavigationShowSiblings = $true;
    }
    elseif ($level -eq "Level3")
    {
    #Same navigation as the parent
    $mywebpub.InheritCurrentNavigation = $true;
    $mywebpub.NavigationShowSiblings = $false;
    }

    $mywebpub.Update()
    $spWeb.Dispose()
    }
}

#Updates the default page of a publishing web to the given page layout

function Update-SPPagePageLayout ([Microsoft.SharePoint.SPWeb]$spWeb, [string] $pageLayoutName, [string] $comment)
{

$mywebpub = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($spWeb)

$pageLayout = $mywebpub.GetAvailablePageLayouts() | Where-Object {$_.Title -eq $pageLayoutName}

$publishingPage = $mywebpub.GetPublishingPages() | Where-Object {$_.Name -eq "default.aspx"}

    Write-Host "Updating the page:" $publishingPage.Name "to Page Layout:" $pageLayout.Title
    $publishingPage.CheckOut();
    $publishingPage.Title = $mywebpub.Title;
    $publishingPage.Layout = $pageLayout;
    $publishingPage.ListItem.Update();
    $publishingPage.CheckIn($comment);
    if ($publishingPage.ListItem.ParentList.EnableModeration)
    {
        $publishingPage.ListItem.File.Approve("Publishing Page Layout correction");
    }
}