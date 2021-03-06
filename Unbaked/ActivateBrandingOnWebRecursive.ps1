    param([string] $webUrl)
    
    Write-Host "Initalizing recursive branding on $nWeb"
    
    #include file
    . "C:\Deployment\Scripts\includeFunctions.ps1"
    . "C:\Deployment\Scripts\GlobalVariables.ps1"

    # set log file
    SetLogFile

    #load the SharePoint snapin
    cls
    loadSnapins

    #load assemblies
    [Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")


    $topWeb = Get-SPWeb webUrl


     Write-Host "Activating features for root web $rootweb"
        
        ActivateFeature $brandingFeatureActivationFeatureID  $topWeb.url "Branding Activation Feature" $false $false
        
     Write-Host "Features activated successfully!!"
        

    $rootWebRelativeUrl = $topWeb.Site.ServerRelativeUrl

     if($rootWebRelativeUrl -ne "/")
        {
          $rootWebRelativeUrl = $rootWebRelativeUrl + "/"
        }
        
        Write-Host "Setting custom masterpage for $topWeb"
        $topWeb.CustomMasterUrl = $rootWebRelativeUrl + "_catalogs/masterpage/ubcfom_templates.master"
        Write-Host "Setting default masterpage for $web"
        $topWeb.MasterUrl = $rootWebRelativeUrl + "_catalogs/masterpage/ubcfom_templates.master"
        Write-Host "Masterpages set! Updating..."
        $topWeb.Update()
        $topWeb.Dispose()
        
    if($topWeb.webs.Count -gt 0)
    {
         foreach($web in $topWeb.webs)
           {
            Write-Host "Setting custom masterpage for $web"
            $web.CustomMasterUrl = $rootWebRelativeUrl + "_catalogs/masterpage/ubcfom_templates.master"
            Write-Host "Setting default masterpage for $web"
            $web.MasterUrl = $rootWebRelativeUrl + "_catalogs/masterpage/ubcfom_templates.master"
            Write-Host "Masterpages set! Updating..."
            $web.Update()
            $web.Dispose()
          }
     }