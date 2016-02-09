<#
.SYNOPSIS
   <A brief description of the script>
.DESCRIPTION
   <A detailed description of the script>
.PARAMETER <paramName>
   <Description of script parameter>
.EXAMPLE
   <An example of using the script>
#>

#Region Configure Adobe PDF Indexing
# ====================================================================================
# Func: Configure-PDFSearchAndIcon
# Desc: Downloads and installs the PDF iFilter, registers the PDF search file type and document icon for display in SharePoint
# From: Adapted/combined from @brianlala's additions, @tonifrankola's http://www.sharepointusecases.com/index.php/2011/02/automate-pdf-configuration-for-sharepoint-2010-via-powershell/
# And : Paul Hickman's Patch 9609 at http://autospinstaller.codeplex.com/SourceControl/list/patches
# ====================================================================================

function Configure-PDFSearch
{
	$PDFiFilterUrl = "http://download.adobe.com/pub/adobe/acrobat/win/9.x/PDFiFilter64installer.zip"
	$SharePointRoot = "$env:CommonProgramFiles\Microsoft Shared\Web Server Extensions\14"

	Write-Host -ForegroundColor White " - Configuring PDF file indexing..."
	$SourceFileLocations = @("$bits\PDF\","$bits\AdobePDF\",$env:TEMP)
	# Look for the installer or the installer zip in the possible locations
	foreach ($SourceFileLocation in $SourceFileLocations)
	{
		if (Get-Item $($SourceFileLocation+"PDFFilter64installer.msi") -ErrorAction SilentlyContinue)
		{
			Write-Host -ForegroundColor White " - PDF iFilter installer found in $SourceFileLocation."
			$iFilterInstaller = $SourceFileLocation+"PDFFilter64installer.msi"
			break
		}
		elseif (Get-Item $($SourceFileLocation+"PDFiFilter64installer.zip") -ErrorAction SilentlyContinue)
		{
			Write-Host -ForegroundColor White " - PDF iFilter installer zip file found in $SourceFileLocation."
			$ZipLocation = $SourceFileLocation
			$SourceFile = $SourceFileLocation+"PDFiFilter64installer.zip"
			break
		}
	}
	# If the MSI hasn't been extracted from the zip yet then extract it
	if (!($iFilterInstaller))
	{
		# If the zip file isn't present then download it first
		if (!($SourceFile))
		{
			Write-Host -ForegroundColor White " - PDF iFilter installer or zip not found, downloading..."
			$ZipLocation = $env:TEMP
			$DestinationFile = $ZipLocation+"\PDFiFilter64installer.zip"
			Import-Module BitsTransfer | Out-Null
			Start-BitsTransfer -Source $PDFiFilterUrl -Destination $DestinationFile -DisplayName "Downloading Adobe PDF iFilter..." -Priority High -Description "From $PDFiFilterUrl..." -ErrorVariable err
			if ($err) {Write-Warning " - Could not download Adobe PDF iFilter!";  break}
			$SourceFile = $DestinationFile
		}
		Write-Host -ForegroundColor White " - Extracting Adobe PDF iFilter installer..."
		$Shell = New-Object -ComObject Shell.Application
		$iFilterZip = $Shell.Namespace($SourceFile)
		$Location = $Shell.Namespace($ZipLocation)
    	$Location.Copyhere($iFilterZip.items())
		$iFilterInstaller = $ZipLocation+"\PDFFilter64installer.msi"
	}
	try
	{
		Write-Host -ForegroundColor White " - Installing Adobe PDF iFilter..."
		Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $iFilterInstaller /passive /norestart" -NoNewWindow -Wait
	}
	catch {$_}
	
	if ((Get-PsSnapin |?{$_.Name -eq "Microsoft.SharePoint.PowerShell"})-eq $null)
	{
	   	Write-Host -ForegroundColor White " - Loading SharePoint Powershell Snapin..."
		$PSSnapin = Add-PsSnapin Microsoft.SharePoint.PowerShell
	}

	Write-Host -ForegroundColor White " - Setting PDF search crawl extension..."
	$searchApplications = Get-SPEnterpriseSearchServiceApplication
	if ($searchApplications)
	{		
		foreach ($searchApplication in $searchApplications)
		{
			try
			{
				Get-SPEnterpriseSearchCrawlExtension -SearchApplication $searchApplication -Identity "pdf" -ErrorAction Stop | Out-Null
				Write-Host -ForegroundColor White " - PDF file extension already set for $($searchApplication.DisplayName)."
			}
			catch
			{
				New-SPEnterpriseSearchCrawlExtension -SearchApplication $searchApplication -Name "pdf" | Out-Null
				Write-Host -ForegroundColor White " - PDF extension for $($searchApplication.DisplayName) now set."
			}
		}
	}
	else {Write-Warning " - No search applications found."}
	Write-Host -ForegroundColor White " - Updating registry..."
	if ((Get-Item -Path Registry::"HKLM\SOFTWARE\Microsoft\Office Server\14.0\Search\Setup\Filters\.pdf" -ErrorAction SilentlyContinue) -eq $null)
	{
		$item = New-Item -Path Registry::"HKLM\SOFTWARE\Microsoft\Office Server\14.0\Search\Setup\Filters\.pdf"
		$item | New-ItemProperty -Name Extension -PropertyType String -Value "pdf" | Out-Null
		$item | New-ItemProperty -Name FileTypeBucket -PropertyType DWord -Value 1 | Out-Null
		$item | New-ItemProperty -Name MimeTypes -PropertyType String -Value "application/pdf" | Out-Null
	}
	if ((Get-Item -Path Registry::"HKLM\SOFTWARE\Microsoft\Office Server\14.0\Search\Setup\ContentIndexCommon\Filters\Extension\.pdf" -ErrorAction SilentlyContinue) -eq $null)
	{
		$registryItem = New-Item -Path Registry::"HKLM\SOFTWARE\Microsoft\Office Server\14.0\Search\Setup\ContentIndexCommon\Filters\Extension\.pdf"
		$registryItem | New-ItemProperty -Name "(default)" -PropertyType String -Value "{E8978DA6-047F-4E3D-9C78-CDBE46041603}" | Out-Null
	}
	##Write-Host -ForegroundColor White " - Restarting SharePoint Foundation Search Service..."
	##Restart-Service SPSearch4
	if ((Get-Service OSearch14).Status -eq "Running")
	{
		Write-Host -ForegroundColor White " - Restarting SharePoint Search Service..."
		Restart-Service OSearch14
	}
	Write-Host -ForegroundColor White " - Done configuring PDF search."
	}

	#Region Configure Adobe PDF Indexing and Display
# ====================================================================================
# Func: Configure-PDFSearchAndIcon
# Desc: Downloads and installs the PDF iFilter, registers the PDF search file type and document icon for display in SharePoint
# From: Adapted/combined from @brianlala's additions, @tonifrankola's http://www.sharepointusecases.com/index.php/2011/02/automate-pdf-configuration-for-sharepoint-2010-via-powershell/
# And : Paul Hickman's Patch 9609 at http://autospinstaller.codeplex.com/SourceControl/list/patches
# ====================================================================================

function Configure-PDFIcon
{
<#
.SYNOPSIS
This function adds an icon for PDF files in SharePoint. If an icon file does not exist, one will be downloaded.
.DESCRIPTION
This function adds an icon for PDF files in SharePoint. If an icon file does not exist, one will be downloaded.
.EXAMPLE
PS C:\> Configure-PDFIcon
.NOTES
This function was derived from the most awesome Brian Lalancette's AutoSPInstaller. You should check it out.
#>
	write-output ""
	$PDFIconUrl = "http://www.adobe.com/images/pdficon_small.gif"
	$SharePointRoot = "$env:CommonProgramFiles\Microsoft Shared\Web Server Extensions\14"
	$DocIconFolderPath = "$SharePointRoot\TEMPLATE\XML"
	$DocIconFilePath = "$DocIconFolderPath\DOCICON.XML"

	Write-Host -ForegroundColor White " - Configuring PDF Icon..."
	$pdfIcon = "icpdf.gif"
	if (!(Get-Item $SharePointRoot\Template\Images\$pdfIcon -ErrorAction SilentlyContinue))
	{
		foreach ($SourceFileLocation in $SourceFileLocations)
		{
			# Check each possible source file location for the PDF icon
			$CopyIcon = Copy-Item -Path $SourceFileLocation\$pdfIcon -Destination $SharePointRoot\Template\Images\$pdfIcon -PassThru -ErrorAction SilentlyContinue
			if ($CopyIcon)
			{
				Write-Host -ForegroundColor White " - PDF icon found at $SourceFileLocation\$pdfIcon"
				break
			}
		}
		if (!($CopyIcon))
		{
			Write-Host -ForegroundColor White " - `"$pdfIcon`" not found; downloading it now..."
			Import-Module BitsTransfer | Out-Null
			Start-BitsTransfer -Source $PDFIconUrl -Destination "$SharePointRoot\Template\Images\$pdfIcon" -DisplayName "Downloading PDF Icon..." -Priority High -Description "From $PDFIconUrl..." -ErrorVariable err
			if ($err) {Write-Warning " - Could not download PDF Icon!"; break}
		}
		if (Get-Item $SharePointRoot\Template\Images\$pdfIcon) {Write-Host -ForegroundColor White " - PDF icon copied successfully."}
		else {Throw}
	}
	$xml = New-Object XML
	$xml.Load($DocIconFilePath)
	if ($xml.SelectSingleNode("//Mapping[@Key='pdf']") -eq $null)
	{
		try
		{
			Write-Host -ForegroundColor White " - Creating backup of DOCICON.XML file..."
			$backupFile = "$DocIconFolderPath\DOCICON_Backup.xml"
			Copy-Item $DocIconFilePath $backupFile
			Write-Host -ForegroundColor White " - Writing new DOCICON.XML..."
			$pdf = $xml.CreateElement("Mapping")
			$pdf.SetAttribute("Key","pdf")
			$pdf.SetAttribute("Value",$pdfIcon)
			$xml.DocIcons.ByExtension.AppendChild($pdf) | Out-Null
		    $xml.Save($DocIconFilePath)
		}
		catch {$_; break}
	}
	Write-Host -ForegroundColor White " - Restarting IIS..."
	iisreset
	Write-Host -ForegroundColor White " - Done configuring PDF indexing and icon display."
	write-output ""
}
#EndRegion
