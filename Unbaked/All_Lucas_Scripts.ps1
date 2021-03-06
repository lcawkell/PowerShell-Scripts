
<#      Add Authentication to Masterpage Gallery

 Parameters: Site url (ex. http://teams.mednet.med.ubc.ca/mysite)

 Description:
 This script will allow any user who can log in to access the masterpage gallery. May be required in special cases where permission
 to the MP gallery is not automatic. Script will break inheritance first.

#>

. "C:\Deployment\Scripts\Lucas\AddAuthenticatedToMPG.ps1" -siteUrl https://?



<#      Activate Branding on Application

 Parameters: Application Url (ex. http://teams.mednet.med.ubc.ca)

 Description:
 This script will activate the FOM branding features and change the master page on every site and web in the specified application

#>

. "C:\Deployment\Scripts\Lucas\ActivateBrandingOnApplicationRecursive.ps1" -applicationUrl http://?




<#      Activate Branding on Site

 Parameters: Application Url (ex. http://teams.mednet.med.ubc.ca/mysite)

 Description:
 This script will activate the FOM branding features and change the master page on every web in the specified site

#>

. "C:\Deployment\Scripts\Lucas\ActivateBrandingOnSiteRecursive.ps1" -siteUrl https://?



<#       Activate Branding on Web
 
 Parameters: Application Url (ex. http://teams.mednet.med.ubc.ca/mysite/myweb)

 Description:
 This script will activate the FOM branding features and change the master page on every web in the specified web including the specified web

#>

. "C:\Deployment\Scripts\Lucas\ActivateBrandingOnWebRecursive.ps1" -webUrl https://?