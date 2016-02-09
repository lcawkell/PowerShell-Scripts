function LC-Add-Web
{
    Param(
    [string]$url,
    [System.Xml.XMLDocument]$xmlDocument,
    [System.Xml.XMLElement]$parentElement,
    [string] $parentFilesystemPath
    )

    Write-Host "Getting web $url"
    $web = Get-SPWeb $url
    $publishingWeb = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($web)
    $relativeUrl = ($web.Url).Substring($web.Url.LastIndexOf("/"))
    $currentFilesystemPath = $parentFilesystemPath+($relativeUrl.Replace("/","\"))

    $xmlWeb = $xmlDocument.CreateElement("web")
    $xmlWeb.SetAttribute("name", $web.Name)
    $xmlWeb.SetAttribute("title", $web.Title)
    $xmlWeb.SetAttribute("url", $relativeUrl)
    $xmlWeb.SetAttribute("template", $web.WebTemplate+"#"+$web.Configuration)
    $xmlWeb.SetAttribute("inheritglobal", $publishingWeb.Navigation.InheritGlobal)
    $xmlWeb.SetAttribute("inheritcurrent", $publishingWeb.Navigation.InheritCurrent)
    $xmlWeb.SetAttribute("globalincludesubsites", $publishingWeb.Navigation.GlobalIncludeSubSites)
    $xmlWeb.SetAttribute("globalincludepages", $publishingWeb.Navigation.GlobalIncludePages)
    $xmlWeb.SetAttribute("currentshowsiblings", $publishingWeb.Navigation.ShowSiblings)
    $xmlWeb.SetAttribute("currentincludesubsites", $publishingWeb.Navigation.CurrentIncludeSubSites)
    $xmlWeb.SetAttribute("currentincludepages", $publishingWeb.Navigation.CurrentIncludePages)

    $parentElement.AppendChild($xmlWeb)

    #foreach ($list in $web.Lists)
    #{
    #    LC-Add-List -list $list -xmlDocument $xmlDocument -ParentElement $xmlWeb
    #}

    LC-Download-Libraries -web $web -rootPath $currentFilesystemPath -parentElement $xmlWeb

    foreach ($subweb in $web.Webs)
    {
        LC-Add-Web -url $subweb.Url -xmlDocument $xmlDocument -parentElement $xmlWeb -parentFilesystemPath $currentFilesystemPath
    }

}



function Save-SPItemsToXml
{
Param(
    [Microsoft.SharePoint.SPListCollection]$itemCollection,
    [string] $rootPath,
    [System.Xml.XmlElement]$ParentElement

)

    $listItems = New-Object Xml

    foreach ($item in $itemCollection)
        {
            if($item.FileSystemObjectType -eq "Folder")
            {
                Save-SPItemsToXml $web.GetFolder($item)
            }
            else
            {
                $file = $item.file
                # Copy the file to the system drive
                $filePath = $path+"\"+$($file.Name)
                $fileBinary = $file.OpenBinary()
                $fileStream = New-Object System.IO.FileStream(($filePath), [System.IO.FileMode]::Create)
                $binaryWriter = New-Object System.IO.BinaryWriter($fileStream)
                $binaryWriter.Write($fileBinary)
                $binaryWriter.Close()

                # Update the XML
                $xmlFile = $xmlList.OwnerDocument.CreateElement("file")
                $xmlFile.SetAttribute("name", $file.Name)
                $xmlFile.SetAttribute("title", $file.Title)
                $xmlFile.SetAttribute("path", $filePath)

                if($($list.Title) -eq "Pages")
                {
                    $xmlFile.SetAttribute("layout", $file.Properties["PublishingPageLayout"])
                }

                $xmlList.AppendChild($xmlFile)
            }
        }
}