Function GetFiles($folder,[int] $index)
{ 

   $tab = "";

   for($i = 0; $i -le $index; $i++)
   {
       $tab = $tab + "&nbsp;&nbsp;&nbsp;"
   }



   $newFolder = $folder.DocumentLibrary.Folders | Where {$_.Name -eq $folder.Name}

   $uniqueAssignments = $newFolder.HasUniqueRoleAssignments

   $stream.WriteLine("<div class='folder'>")

   if($uniqueAssignments)
   {
    $stream.WriteLine($tab+"<a href='#' class='btnFolder'>"+$folder.Name+"</a><br/>")
   }
   else
   {
    $stream.WriteLine($tab+"<h5>"+$folder.Name+"</h5><br/>")
   }



   if(($folder.SubFolders.Count -gt 0) -or ($uniqueAssignments))
   {
        $stream.WriteLine("<div class='btnHidden'>")
   }

                                    if($uniqueAssignments)
                                    {
                  
                  
                                    $stream.WriteLine("<div class='btnPermissions'>")
                                    $stream.WriteLine("<a href='#'>"+ "Show Permissions" +"</a>")
                                    $stream.WriteLine("<table class='permissions'>")
                                    $stream.WriteLine("<tr><th>Member</th><th>Permission</th></tr>")
                  
                                    foreach ($assignment in $newFolder.RoleAssignments)
                                    {
                                       $permissions = "";
                                        
                                        if($assignment.RoleDefinitionBindings.Count -gt 1)
                                        {
                                            for($i = 0;$i -lt $assignment.RoleDefinitionBindings.Count; $i++)
                                            {
                                                $permissions = $permissions + $assignment.RoleDefinitionBindings.Name[$i] + "; "
                                            }
                                        }
                                        else
                                        {
                                            $permissions = $assignment.RoleDefinitionBindings.Name
                                        }
                  
                                        $stream.WriteLine("<tr>")
                                       $stream.WriteLine("<td>")
                                        $stream.WriteLine($assignment.Member.Name)
                                        $stream.WriteLine("</td>")
                                        $stream.WriteLine("<td>")
                                        $stream.WriteLine($permissions)
                                        $stream.WriteLine("</td>")
                                        $stream.WriteLine("</tr>")
                                    }
                                    $stream.WriteLine("</table>")
                                    $stream.WriteLine("</div>")
                                }
                                else
                                {
                                    
                                }




   # Use recursion to loop through all subfolders.
   foreach ($subFolder in $folder.SubFolders)
   {
       
        GetFiles -folder $subFolder -index ($index+1)
   }
   if(($folder.SubFolders.Count -gt 0) -or ($newFolder.HasUniqueRoleAssignments))
   {
     $stream.WriteLine("</div>")
   }
   $stream.WriteLine("</div>")
 }



function Get-WebPermissions($web, [bool]$includeItems, [bool]$recursive)
{

$lists = $web.Lists

if($lists.Count -gt 0)
{

    $stream.WriteLine("<h2>" + $web.Title + "</h2>")

    $stream.WriteLine("<div class='btnPermissions'>")
    $stream.WriteLine("<a href='#'>Show Permissions</a>")
    $stream.WriteLine("<table class='permissions'>")
    $stream.WriteLine("<tr><th>Member</th><th>Permission</th></tr>")
    foreach($member in $web.Permissions)
    {
         $stream.WriteLine("<tr>")
         $stream.WriteLine("<td>" + $member.Member + "</td>")
         $stream.WriteLine("<td>" + $permissionMasks.Get_Item($member.PermissionMask.ToString()) + "</td>")
         $stream.WriteLine("</tr>")
    }
    $stream.WriteLine("</table>")
    $stream.WriteLine("</div>")
    $stream.WriteLine("<br/>")
    
  

    foreach ($list in $lists)
    {
       

        if($list.HasUniqueRoleAssignments -eq "True")
        {
            if($list.Permissions.Count -gt 0)
            {
                $stream.WriteLine("<div class='library'>")
                $stream.WriteLine("<h3><a href='#' class='btnHide'>" + $list.Title + "</a></h3>")
                
                $stream.WriteLine("<div class='hidden'>")
                $stream.WriteLine("<div class='btnPermissions'>")
                $stream.WriteLine("<a href='#'>Show Permissions</a>")
                $stream.WriteLine("<table class='permissions'>")
                $stream.WriteLine("<tr><th>Member</th><th>Permission</th></tr>")
                foreach($member in $list.Permissions)
                {
                    $stream.WriteLine("<tr>")
                    $stream.WriteLine("<td>" + $member.Member + "</td>")
                    $stream.WriteLine("<td>" + $permissionMasks.Get_Item($member.PermissionMask.ToString()) + "</td>")
                    $stream.WriteLine("</tr>")
                }
                $stream.WriteLine("</table>")
                $stream.WriteLine("</div>")

                $uniqueItems = 0;
                
                if($includeItems)
                {
                    if($list.Folders.count -gt 0)
                    {
                        $stream.WriteLine("<div class='files'>")
                        $stream.WriteLine("<a href='#' class='btnHide'><h4>Folders</h4></a>")
                        $stream.WriteLine("<div class='hidden'>")

                        foreach($folder in $list.RootFolder.SubFolders)
                        {
                            GetFiles -folder $folder -index 0
                        }

                  #          foreach($item in $list.Folders)
                  #          {
                  #              if($item.HasUniqueRoleAssignments -eq $true)
                  #              {
                  #
                  #
                  #                  $stream.WriteLine("<div class='btnPermissions'>")
                  #                  $stream.WriteLine("<a href='#'>"+ $item.Name +"</a>")
                  #                  $stream.WriteLine("<table class='permissions'>")
                  #                  $stream.WriteLine("<tr><th>Member</th><th>Permission</th></tr>")
                  #
                  #                  foreach ($assignment in $item.RoleAssignments)
                  #                  {
                  #                     $permissions = "";
                  #                      
                  #                      if($assignment.RoleDefinitionBindings.Count -gt 1)
                  #                      {
                  #                          for($i = 0;$i -lt $assignment.RoleDefinitionBindings.Count; $i++)
                  #                          {
                  #                              $permissions = $permissions + $assignment.RoleDefinitionBindings.Name[$i] + "; "
                  #                          }
                  #                      }
                  #                      else
                  #                      {
                  #                          $permissions = $assignment.RoleDefinitionBindings.Name
                  #                      }
                  #
                  #                      $stream.WriteLine("<tr>")
                  #                     $stream.WriteLine("<td>")
                  #                      $stream.WriteLine($assignment.Member.Name)
                  #                      $stream.WriteLine("</td>")
                  #                      $stream.WriteLine("<td>")
                  #                      $stream.WriteLine($permissions)
                  #                      $stream.WriteLine("</td>")
                  #                      $stream.WriteLine("</tr>")
                  #                  }
                  #                  $stream.WriteLine("</table>")
                  #                  $stream.WriteLine("</div>")
                  #              }
                  #              else
                  #              {
                  #                  $stream.WriteLine("" + $item.Name + " -Inherits<br/>")
                  #              }
                  #          }
                                   
                       $stream.WriteLine("</div>")
                       $stream.WriteLine("</div>")
                    }
                }

               
            }
        }
        else
        {
            $stream.WriteLine("<div class='library'>")
            $stream.WriteLine("<h3>" + $list.Title + " -Inherited</h3>")
            $stream.WriteLine("</div>")
        }
        
        $stream.WriteLine("</div>")
        $stream.WriteLine("</div>")
        $stream.WriteLine("</div>")
    }
    
}

    if(($web.Webs.Count -gt 0) -and ($recursive))
    {
        foreach($subWeb in $web.Webs)
        {
            Get-WebPermissions -web $subWeb -includeItems $includeItems -recursive $recursive
        }
    }

}

$permissionMasks = @{
"1011028719" = "Contribute";
"138612833" = "Read";
"134287360" = "Limited Access";
"196641" = "Restricted Read";
"1011028991" = "Approve";
"2129075183" = "Manage Hierarchy";
"1012866047" = "Designers";
"FullMask" = "Full Control"
}

New-Item -Force -ItemType directory -Path "C:\out\"

$currentDate = Get-Date
$stream = [System.IO.StreamWriter] "C:\out\permissionreport.html"
$site = Get-SPSite https://teams.test.mednet.med.ubc.ca/do/mdup/smp/records_management
$rootWeb = $site.RootWeb

$stream.WriteLine("<html>")
$stream.WriteLine("<head>")
$stream.WriteLine("<style>")
$stream.WriteLine("table {border:1px solid black}")
$stream.WriteLine("table.permissions {display:none;}")
$stream.WriteLine("th {border-bottom:1px solid black}")
#$stream.WriteLine(".site > tbody > tr:nth-child(even) {}")
$stream.WriteLine("td{vertical-align:top;}")
$stream.WriteLine("a {font-weight:bold; font-size: 1.1em;}")
$stream.WriteLine(".site {position:relative; left:1em;}")
$stream.WriteLine(".library {position:relative; left:1.3em;}")
$stream.WriteLine(".library .hidden {display:none;}")
$stream.WriteLine(".files {position:relative; left:1.3em;}")
$stream.WriteLine(".files .hidden {display:none;}")
$stream.WriteLine(".folder .btnHidden {display: none;}")



$stream.WriteLine("</style>")
$stream.WriteLine("</head>")
$stream.WriteLine("<body>")
$stream.WriteLine("<h1>Site Permissions Report</h1>");
$stream.WriteLine("Created on " + $currentDate)
$stream.WriteLine("<br/>")
Get-WebPermissions -web $rootWeb -includeItems $true -recursive $true
$stream.WriteLine("</body>")
$stream.WriteLine("</html>")
$stream.Close();

