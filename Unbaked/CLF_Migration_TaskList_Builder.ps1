$projectSite = Get-SPWeb https://projects.mednet.med.ubc.ca/clf_migration
$mSites = $projectSite.lists["Migration Sites"]
$taskList = $projectSite.lists["Migration Tasks"]



foreach($sItem in $mSites.items)
{
###
#   Prilim Tasks
###
      $item = $taskList.items.add()
    $item["Task"] = "Create New Site"
    $item["Migration_x0020_Site"] = $sItem["ID"]
    $item["Task_x0020_Category"] = "Preliminary Tasks"
    $item.Update()
    
        $item = $taskList.items.add()
    $item["Task"] = "Plugins"
    $item["Migration_x0020_Site"] = $sItem["ID"]
    $item["Task_x0020_Category"] = "Preliminary Tasks"
    $item.Update()
    
        $item = $taskList.items.add()
    $item["Task"] = "Remove Users"
    $item["Migration_x0020_Site"] = $sItem["ID"]
    $item["Task_x0020_Category"] = "Preliminary Tasks"
    $item.Update()
    
        $item = $taskList.items.add()
    $item["Task"] = "Edit Default Content"
    $item["Migration_x0020_Site"] = $sItem["ID"]
    $item["Task_x0020_Category"] = "Preliminary Tasks"
    $item.Update()
 
 ###
#   Exporting Tasks
###
   
        $item = $taskList.items.add()
    $item["Task"] = "Export Site Content"
    $item["Migration_x0020_Site"] = $sItem["ID"]
    $item["Task_x0020_Category"] = "Exporting"
    $item.Update()
    
        $item = $taskList.items.add()
    $item["Task"] = "Prepare XML File"
    $item["Migration_x0020_Site"] = $sItem["ID"]
    $item["Task_x0020_Category"] = "Exporting"
    $item.Update()
    
 
 ###
#   Importing Tasks
###
   
        $item = $taskList.items.add()
    $item["Task"] = "Add Users"
    $item["Migration_x0020_Site"] = $sItem["ID"]
    $item["Task_x0020_Category"] = "Importing"
    $item.Update()
    
        $item = $taskList.items.add()
    $item["Task"] = "Import Site Content"
    $item["Migration_x0020_Site"] = $sItem["ID"]
    $item["Task_x0020_Category"] = "Importing"
    $item.Update()
    
        $item = $taskList.items.add()
    $item["Task"] = "Remove Users"
    $item["Migration_x0020_Site"] = $sItem["ID"]
    $item["Task_x0020_Category"] = "Importing"
    $item.Update()
    
 
 ###
#   Post-Import Tasks
###
   
        $item = $taskList.items.add()
    $item["Task"] = "Sub-Procedures"
    $item["Migration_x0020_Site"] = $sItem["ID"]
    $item["Task_x0020_Category"] = "Post-import Tasks"
    $item.Update()
    
        $item = $taskList.items.add()
    $item["Task"] = "Theme Options Items"
    $item["Migration_x0020_Site"] = $sItem["ID"]
    $item["Task_x0020_Category"] = "Post-import Tasks"
    $item.Update()
    
        $item = $taskList.items.add()
    $item["Task"] = "Settings Menu Items"
    $item["Migration_x0020_Site"] = $sItem["ID"]
    $item["Task_x0020_Category"] = "Post-import Tasks"
    $item.Update()
    
        $item = $taskList.items.add()
    $item["Task"] = "Testing"
    $item["Migration_x0020_Site"] = $sItem["ID"]
    $item["Task_x0020_Category"] = "Post-import Tasks"
    $item.Update()
    
            $item = $taskList.items.add()
    $item["Task"] = "Non-migrateable item notes"
    $item["Migration_x0020_Site"] = $sItem["ID"]
    $item["Task_x0020_Category"] = "Post-import Tasks"
    $item.Update()
    
        $item = $taskList.items.add()
    $item["Task"] = "Site Review"
    $item["Migration_x0020_Site"] = $sItem["ID"]
    $item["Task_x0020_Category"] = "Post-import Tasks"
    $item.Update()
    
        $item = $taskList.items.add()
    $item["Task"] = "Migrator Sign-off"
    $item["Migration_x0020_Site"] = $sItem["ID"]
    $item["Task_x0020_Category"] = "Post-import Tasks"
    $item.Update()
    
}