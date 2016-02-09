#Requires -Version 3
#Requires -Modules ActiveDirectory
#Requires -Modules LCFunctions
#Requires -RunAsAdministrator

<#

.SYNOPSIS
Records MedNet (or really any other site) into XML files and then creates a new site based off the old one.

.DESCRIPTION

.PARAMETER
    -Url
        Specifies the URL of the site to migrate. This must lead to a site collection.

.PARAMETER
    -destinationUrl
        Where to migrate the site to. If one is not specified then it will keep the same URL

.PARAMETER
    -filePath
        Specifies the file path to record everything to. If one is not specified then the default
        location C:\out\ will be used.

.EXAMPLE
    C:\PS> .\MigrateMedNet.ps1 -Url https://mednet.med.ubc.ca

.EXAMPLE
    C:\PS> .\MigrateMedNet.ps1 -Url https://mednet.med.ubc.ca -filePath C:\out\MedNet



#>

[CmdletBinding()]
Param
(
[Parameter(Mandatory=$true)]
[string]$url,
[string]$destinationUrl,
[string]$filePath,
[Switch]$useInputXml
)

if ( (Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null )
{
    Add-PsSnapin Microsoft.SharePoint.PowerShell
}

Remove-Module LCFunctions | Out-Null

Import-Module LCFunctions

if($destinationUrl -eq $null)
{
    $destinationUrl = $url
}

if($filePath -eq $null)
{
    $filePath = "$env:SystemDrive\out\"
}

$scriptName = "C"
$startDate = Get-Date

$workingDirectory = "$($filePath)$($scriptName)$($startDate.ToFileTime().GetHashCode())"
$inputDirectory = "C:\input\Migration"
$inputFile = $inputDirectory + "\" + "input.xml"
$filename = "$workingDirectory\output.xml"
$outputXml = "output-$($startDate.ToFileTime())"
$rootSite = $url

$xmlTemplate = @"
<sitestructure path="$workingDirectory" input="$inputDirectory" destination="$destinationUrl">
</sitestructure>
"@

if((Test-Path $workingDirectory) -ne $true) {New-Item $workingDirectory -ItemType directory | Out-Null}

# Create XML from template
$xmlTemplate | Out-File $filename

$xml = New-Object XML
$xml.Load($filename)

if($useInputXml)
{
    $inputxml = New-Object XML
    $inputxml.Load($inputFile)
}


$site = Get-SPSite $rootSite

#New-SPSiteToXmlInput -path "$workingDirectory\input.xml" -site $site
if($useInputXml)
{
    foreach($xmlSite in $inputxml.input.reorganize.site)
    {
        Save-SPSiteToXml -site $site -parentElement $xml.FirstChild -xmlInput $xmlSite -topLevel
    }
}
else
{
    Save-SPSitToXml -site $site -parentElement $xml.FirstChild
}

$xml.Save($filename)

New-SPSiteFromXml -xmlPath $filename