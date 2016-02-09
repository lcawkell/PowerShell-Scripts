<#
.SYNOPSIS
This script records the details of a SharePoint web into an xml file

.DESCRIPTION
The purpose of this script is to download the details of a 
Microsoft.SharePoint.SPWeb object into a given XML file. 
That XML file can then be used to recreate the web. The download will
include files which will be downloaded into directories at the given path.

.PARAMETER url
The web that should be recorded. The script will also include all sub-webs recursivly

.PARAMETER xmlDocument
This is the main XML document that will store the data. This xml document should have
a root node with an attribute "path" that has the xml file location on the computer. Here
is a sample structure:

<structure path="C:\out\xmlFile.xml">
    <site>

    </site>
</structure

.PARAMETER parentElement
Optionally include the parent element that this SPWeb will be recorded under.
If no parent element is specified then the web will be created under the top node.

.EXAMPLE

.LINK
LC-Add-List

.LINK
LC-Download-Libraries

.LINK
LC-Add-Web

#>


[CmdletBinding()]
Param(
[string]$url,
[System.Xml.XMLDocument]$xmlDocument,
[System.Xml.XMLElement]$parentElement
)

$xmlLocation = ($xmlDocument.FirstChild.path)
$parentFilesystemPath = $xmlLocation.Substring(0,$xmlLocation.LastIndexOf("\"))

Write-Host "Recoding details of web: $url"
$web = Get-SPWeb $url

# The publishing version of the web contains navigation settings
Write-Debug "Trying to get the publishing version of the web..."
$publishingWeb = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($web)
$pubWebNavigation = $publishingWeb.Navigation

# The relative web will be used to understand where we are in the
# file system path. This is mostly used when downloading the web libraries
$relativeUrl = ($web.Url).Substring($web.Url.LastIndexOf("/"))
Write-Debug "The relative path of $web is $relativeUrl"
$currentFilesystemPath = $parentFilesystemPath+($relativeUrl.Replace("/","\"))
Write-Debug "The new file system path is: $currentFilesystemPath"

# We need to record the web details including navigation settings
Write-Debug "Creating new element in specified XML document"
$xmlWeb = $xmlDocument.CreateElement("web")
Write-Debug "Adding Attributes"
$xmlWeb.SetAttribute("name", $web.Name)
$xmlWeb.SetAttribute("title", $web.Title)
$xmlWeb.SetAttribute("url", $relativeUrl)
$xmlWeb.SetAttribute("template", $web.WebTemplate+"#"+$web.Configuration)
$xmlWeb.SetAttribute("inheritglobal", $pubWebNavigation.InheritGlobal)
$xmlWeb.SetAttribute("inheritcurrent", $pubWebNavigation.InheritCurrent)
$xmlWeb.SetAttribute("globalincludesubsites", $pubWebNavigation.GlobalIncludeSubSites)
$xmlWeb.SetAttribute("globalincludepages", $pubWebNavigation.GlobalIncludePages)
$xmlWeb.SetAttribute("currentshowsiblings", $pubWebNavigation.ShowSiblings)
$xmlWeb.SetAttribute("currentincludesubsites", $pubWebNavigation.CurrentIncludeSubSites)
$xmlWeb.SetAttribute("currentincludepages", $pubWebNavigation.CurrentIncludePages)

$parentElement.AppendChild($xmlWeb)

# Get all the list details so we can recreate later
# TODO
#foreach ($list in $web.Lists)
#{
#    LC-Add-List -list $list -xmlDocument $xmlDocument -ParentElement $xmlWeb
#}

# This will download all the libraries on the current web including the files
# but is it currently limited to only default libraries. It will not create new libraries
LC-Download-Libraries -web $web -rootPath $currentFilesystemPath -parentElement $xmlWeb

# We need to iterate through all the sub webs and do it all over again!
foreach ($subweb in $web.Webs)
{
    LC-Add-Web -url $subweb.Url -xmlDocument $xmlDocument -parentElement $xmlWeb -parentFilesystemPath $currentFilesystemPath
}

$web.dispose()