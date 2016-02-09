###
#
# Global Variables
#
###

$MedNetUrl = "https://test.mednet.med.ubc.ca/AboutUs" #Root url to base the download off

$xmlTemplate = @'

<SiteConfiguration>


</SiteConfiguration>

'@

#* Write to log file (.txt)

#* Create main info file .(xml)

#* Get Site Information

#* Save libraries & Lists



function CreateXMLConfigurationFile
{
Param(
    [string]$xmlTemplate,
    [Parameter(Mandatory=$true)]
    [string]$rootSite,
    [string]$path = "C:\out\"
    )

    $rootSite = "https://test.mednet.med.ubc.ca"
    $path = "C:\out\"

    $site = Get-SPSite $rootSite
    $path = $path + $site.RootWeb.Title + "-" + (Get-Date).ToShortDateString() + "-" + (Get-Date).ToShortTimeString() 

    if($xmlTemplate -eq $null -or $xmlTemplate -eq "")
    {
        $xmlTemplate = @'

<SiteConfiguration>


</SiteConfiguration>

'@
    }
    
    $xmlTemplate | Out-File
}


function DownloadMedNet()
{
    # Start with main site

    # Download 

}



#$s = Get-SPSite "https://test.mednet.med.ubc.ca"
#$files = $s.RootWeb.GetFolder("Pages").Files
#foreach ($file in $files) {
#    Write-host $file.Name
#    $b = $file.OpenBinary()
#    $fs = New-Object System.IO.FileStream(("c:\out\MedNetOut\"+$file.Name), [System.IO.FileMode]::Create)
#    $bw = New-Object System.IO.BinaryWriter($fs)
#    $bw.Write($b)
#    $bw.Close()
#}
