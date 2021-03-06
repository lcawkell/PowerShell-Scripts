    $site = Get-SPSite https://teams.mednet.med.ubc.ca/sites/brandingtest
    $siteUrl = $site.Url
    
    ActivateFeature "f6924d36-2fa8-4f0b-b16d-06b7250180fa" $siteUrl "Publishing Infrastructure Feature" $false $false
    ActivateFeature $UBCFOMBrandingAssetsFeatureGuid $site.url "Branding Assets Feature" $false $false
    
    $rootweb = $site.RootWeb
    
    ActivateFeature $brandingFeatureActivationFeatureID  $rootweb.url "Branding Activation Feature" $false $false
    
    $rootweb.CustomMasterUrl = "/_catalogs/masterpage/ubcfom_templates.master"
    $rootweb.Update()
    
    $allWebs = $site.AllWebs
    
    foreach($web in $allWebs)
    {
        $web.AllProperties["__InheritsCustomMasterUrl"] = "true"
        $web.Update()
    }