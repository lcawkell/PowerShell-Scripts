
    param([string] $siteUrl)
    
    Write-Host "Initalizing recursive branding on $nSite"
    
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
    
    $site = Get-SPSite $siteUrl
 
    $siteUrl = $site.Url
    
    Write-Host "Activating features for site $siteUrl"
    
    ActivateFeature "f6924d36-2fa8-4f0b-b16d-06b7250180fa" $siteUrl "Publishing Infrastructure Feature" $false $false
    ActivateFeature $UBCFOMBrandingAssetsFeatureGuid $site.url "Branding Assets Feature" $false $false
    
    $rootweb = $site.RootWeb
    
    Write-Host "Activating features for root web $rootweb"
    
    ActivateFeature $brandingFeatureActivationFeatureID  $rootweb.url "Branding Activation Feature" $false $false
    
    Write-Host "Features activated successfully!!"
    
    
    $rootWebRelativeUrl = $rootweb.ServerRelativeUrl
    
    Write-Host "before" $rootWebRelativeUrl
    
    if($rootWebRelativeUrl -ne "/")
    {
      $rootWebRelativeUrl = $rootWebRelativeUrl + "/"
    }
    
    Write-Host "after" $rootWebRelativeUrl

    $allWebs = $site.AllWebs
    
    foreach($web in $allWebs)
    {
        Write-Host "Setting custom masterpage for $web"
        $web.CustomMasterUrl = $rootWebRelativeUrl + "_catalogs/masterpage/ubcfom_templates.master"
        Write-Host "Setting default masterpage for $web"
        $web.MasterUrl = $rootWebRelativeUrl + "_catalogs/masterpage/ubcfom_templates.master"
        Write-Host "Masterpages set! Updating..."
        $web.Update()
        $web.Dispose()
    }


