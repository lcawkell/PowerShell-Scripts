[System.Reflection.Assembly]::LoadWithPartialName(“Microsoft.SharePoint”) > $null

function printUserList
{
    param(
            [Parameter(Mandatory=$true)]
            [hashtable]$userObject
        )



}



$applications = Get-SPWebApplication

$userCollection = $null
$userCollection = @{}

foreach($application in $applications)
{

    foreach($site in $application.Sites)
    {


        $web = $site.openweb()
        $siteUsers = $web.SiteUsers

        foreach($user in $siteUsers)
        {

            $displayName = $user.DisplayName

            if($displayName -match ",")
            {
                Write-Host "$displayName contains ,"
                $displayNameFirst = $displayName.Substring($displayName.IndexOf(",")+2)
                $displayNameLast = $displayName.Substring(0, $displayName.IndexOf(","))
                $displayName = "$displayNameFirst $displayNameLast"
            }


            $userClass = new-object psobject -Property @{
               displayName = $displayName
               login = $user.LoginName
               email = $user.Email
               site = $user.ParentWeb
               admin = $admin = $user.IsSiteAdmin
            }


            $userCollection.Add($userClass, $displayName)

        }


    }
}


$Users > C:\out\MedNetPermissionsFull.txt