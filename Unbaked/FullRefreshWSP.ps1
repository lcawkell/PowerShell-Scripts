cls

$wsp = "UBCFOM.RSSAggregator.wsp"
$path = "C:\WSP\"

Write-Host "Disabling feature: " (Get-SPFeature -Identity e160f83e-ddc8-4985-8bd6-0d0b325f0367).DisplayName
Disable-SPFeature -Identity e160f83e-ddc8-4985-8bd6-0d0b325f0367 -Url "https://test.mednet.med.ubc.ca/" -Confirm:$false
Start-Sleep -Seconds 10
Write-Host "Done!"

Write-Host "Uninstalling Solution: " (Get-SPSolution -Identity $wsp).Name
Uninstall-SPSolution -Identity $wsp -Confirm:$false
Start-Sleep -Seconds 60
Write-Host "Done!"

Write-Host "Removing Solution: " (Get-SPSolution -Identity $wsp).Name
Remove-SPSolution -Identity $wsp -Confirm:$false
Start-Sleep -Seconds 10
Write-Host "Done!"

Write-Host "Adding Solution: " $wsp
Add-SPSolution -LiteralPath $path$wsp -Confirm:$false
Start-Sleep -Seconds 60
Write-Host "Done!"

Write-Host "Installing Solution: " (Get-SPSolution -Identity $wsp).Name
Install-SPSolution -Identity $wsp -GACDeployment -Force -Confirm:$false
Start-Sleep -Seconds 60
Write-Host "Done!"

Get-SPSolution -Identity $wsp

Write-Host "Restarting Service: " (Get-Service -Name SPTimerV4).DisplayName
Restart-Service SPTimerV4
Start-Sleep -Seconds 20
Write-Host "Done!"

Write-Host "Enabling feature: " (Get-SPFeature -Identity e160f83e-ddc8-4985-8bd6-0d0b325f0367).DisplayName
Enable-SPFeature -Identity e160f83e-ddc8-4985-8bd6-0d0b325f0367 -Url "https://test.mednet.med.ubc.ca/" -Confirm:$false
Start-Sleep -Seconds 15
Write-Host "Done! All complete."