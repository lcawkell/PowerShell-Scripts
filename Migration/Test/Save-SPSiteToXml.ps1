<#






#>

function Save-SPSiteToXml
{
[CmdletBinding()]
Param(
[Parameter(Mandatory=$true,ParameterSetName="SiteDocument")]
[Parameter(Mandatory=$true,ParameterSetName="SiteElement")]
[Microsoft.SharePoint.SPSite]$site,
[Parameter(Mandatory=$true,ParameterSetName="WebDocument")]
[Parameter(Mandatory=$true,ParameterSetName="WebElement")]
[Parameter(Mandatory=$true,ParameterSetName="elementScope")]
[Microsoft.SharePoint.SPWeb]$web,
[Parameter(Mandatory=$true,ParameterSetName="SiteElement")]
[Parameter(Mandatory=$true,ParameterSetName="WebElement")]
[System.Xml.XmlElement]$parentElement,
[Parameter(Mandatory=$true,ParameterSetName="SiteDocument")]
[Parameter(Mandatory=$true,ParameterSetName="WebDocument")]
[System.Xml.XmlDocument]$parentDocument
)


    if($site -ne $null)
    {
        if ($parentElement -eq $null)
        {
            $xmlDocument = $parentDocument
            $xmlElement = $xmlDocument.CreateElement("Site")
            $xmlDocument.AppendChild($xmlElement) | Out-Null
        }
        elseif ($parentDocument -eq $null)
        {
            $xmlDocument = $parentElement.OwnerDocument
            $xmlElement = $xmlDocument.CreateElement("Site")
            $parentElement.AppendChild($xmlElement) | Out-Null
        }

        $xmlElement.SetAttribute("name", $site.RootWeb.Name)
        $xmlElement.SetAttribute("title", $site.RootWeb.Title)
        $xmlElement.SetAttribute("url", $site.Url)

        foreach($web in $site.RootWeb.Webs)
        {
            Save-SPSiteToXml -web $web -parentElement $xmlElement
        }
    }
    else
    {
        if ($parentElement -eq $null)
        {
            $xmlDocument = $parentDocument
            $xmlElement = $xmlDocument.CreateElement("Web")
            $xmlDocument.AppendChild($xmlElement) | Out-Null
        }
        elseif ($parentDocument -eq $null)
        {
            $xmlDocument = $parentElement.OwnerDocument
            $xmlElement = $xmlDocument.CreateElement("web")
            $parentElement.AppendChild($xmlElement) | Out-Null
        }

        $xmlElement.SetAttribute("name", $web.Name)
        $xmlElement.SetAttribute("title", $web.Title)
        $xmlElement.SetAttribute("url", $web.Url)

        foreach($web in $web.Webs)
        {
            Save-SPSiteToXml -web $web -parentElement $xmlElement
        }
    }




}