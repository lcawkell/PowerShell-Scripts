function New-SPSiteToXmlInput
{
Param
(
[string]$path,
[Microsoft.SharePoint.SPSite]$site
)

$xmlDocument = New-Object Xml

$xmlInput = $xmlDocument.CreateElement("input")

$xmlDocument.AppendChild($xmlInput)

$xmlReorganize = $xmlDocument.CreateElement("reorganize")

$xmlInput.AppendChild($xmlReorganize)

$xmlSite = $xmlDocument.CreateElement("site")

$xmlReorganize.AppendChild($xmlSite)

foreach($web in $site.RootWeb.Webs)
{

}

$xmlDocument.Save($path)

}

function New-SPWebToXmlInput
{
Param
(
[System.Xml.XmlElement]$parentElement,
[Microsoft.SharePoint.PowerShell]$web
)

$xmlDocument = $parentElement.OwnerDocument

$xmlWeb = $xmlDocument.CreateElement("web")

$xmlWeb.SetAttribute("title", $web.title)

foreach($subweb in $web.webs)
{
    New-SPWebToXmlInput -parentElement $xmlWeb -web $subweb
}

}