################################################################################
# Global Variables
################################################################################

$IntranetName = "MedNet"
$rootSiteCollectionURL = "http://mednet.med.ubc.ca"
$rootSiteUrl = "http://mednet.med.ubc.ca/"
$contentTypeHubUrl = "http://mednet.med.ubc.ca/cth"
$searchCentreURL = "http://mednet.med.ubc.ca/search"
$siteColAdminDefault = "fom\mtena_admin"
$systemAccount = "fom\mtena_admin"

################################################################################
# Site Templates
################################################################################

$templateBlankInternet = "BLANKINTERNET#2"
$templateBlog = "BLOG#0"


################################################################################
# List Templates
################################################################################

$docLibTemplate = [Microsoft.SharePoint.SPListTemplateType]::DocumentLibrary
$pageLibTemplate = [Microsoft.SharePoint.SPListTemplateType]::DocumentLibrary
$eventsListTemplate = [Microsoft.SharePoint.SPListTemplateType]::Events
$announcementsListTemplate = [Microsoft.SharePoint.SPListTemplateType]::Announcements
$linksListTemplate = [Microsoft.SharePoint.SPListTemplateType]::Links
$contactsListTemplate = [Microsoft.SharePoint.SPListTemplateType]::Contacts
$imageLibTemplate = [Microsoft.SharePoint.SPListTemplateType]::PictureLibrary
$genericListTemplate = [Microsoft.SharePoint.SPListTemplateType]::GenericList

################################################################################
# Field Types
################################################################################
$spFieldTypeText = [Microsoft.SharePoint.SPFieldType]::Text
$spFieldTypeTextMulti = [Microsoft.SharePoint.SPFieldType]::Note
$spFieldTypeDateTime = [Microsoft.SharePoint.SPFieldType]::DateTime
$spFieldTypeChoice = [Microsoft.SharePoint.SPFieldType]::Choice
$spFieldTypeCalculated = [Microsoft.SharePoint.SPFieldType]::Calculated
################################################################################
# Page Layouts
################################################################################
$BlankPagelayout = "Blank Web Part page"
$OneColumnUBCPageLayout = "UBC FOM 1 Column Inner Page Layout"
$TwoColumnUBCPageLayout = "UBC FOM 2 Column Inner Page Layout"
$HomeUBCPageLayout = "UBC FOM Home Page Layout"
################################################################################
# OOB Features
################################################################################

$taxonomyFeatureGuid = "73EF14B1-13A9-416b-A9B5-ECECA2B0604C"
$contentTypeHubFeatureGuid ="9a447926-5937-44cb-857a-d3829301c73b"
$sharepointServerSTDFeatureGuid ="b21b090c-c796-4b0f-ac0f-7ef1659c20ae"

################################################################################
# Custom Features
################################################################################
$UBCFOMIntranetWebPartsFeatureGuid = "31ccb6aa-64db-492d-8e00-f08151c92033"
$GlobalContentTypesFeatureGuid ="651b980e-7757-4acd-8c63-9990a8ddcf25"
$UBCFOMIntranetPagesAndLayoutsFeatureGuid ="325d2ae6-ea24-43f4-b42a-ffb2aaab8f98"
$UBCFOMBrandingAssetsFeatureGuid = "4fbba0f7-453e-40a2-b268-345f8bb9ec88"
$brandingFeatureActivationFeatureID = "c6fb1fb5-01fc-454c-a893-5adabfce7235"

################################################################################
# Deploy Solutions Location
################################################################################

#---------------DEV--------------------------
#$sourceScriptsDirectory = "C:\_Code_Mtena\UBC FOM Intranet\UBC FOM Intranet\Deployment\Scripts"
#$sourceScriptsDirectory = "C:\_Code_Ben\UBC FOM Intranet\UBC FOM Intranet\Deployment\Scripts"

#$wspDirectory = "C:\_Code_Mtena\UBC FOM Intranet\UBC FOM Intranet\Deployment\Scripts\WSP"
#$wspDirectory = "C:\_Code_Ben\UBC FOM Intranet\UBC FOM Intranet\Deployment\Scripts\WSP"

#---------------STAGING--------------------------
#$sourceScriptsDirectory = "C:\UBC Intranet Deployment"
#---------------PROD--------------------------
$sourceScriptsDirectory = "C:\Deployment\Scripts"
$wspDirectory = "C:\Deployment\Scripts\WSP"


################################################################################
# Web Urls
################################################################################

$aboutUsRelPath = "AboutUs"
$aboutUsURL = $rootSiteUrl + $aboutUsRelPath
$OurOrganizationRelPath = "AboutUs/OurOrganization"
$OurOrganizationURL = $rootSiteUrl + $OurOrganizationRelPath
$OurPeopleRelPath = "AboutUs/OurPeople"

$OurPeopleURL = $rootSiteUrl + $OurPeopleRelPath

$SeniorLeadersRelPath = "AboutUs/OurPeople/SeniorLeaders"
$SeniorLeadersURL = $rootSiteUrl + $SeniorLeadersRelPath

$OrganizationChartsRelPath = "AboutUs/OurPeople/OrganizationCharts"
$OrganizationChartsURL = $rootSiteUrl + $OrganizationChartsRelPath
$AdminAndGoverningBodiesRelPath = "AboutUs/AdminAndGoverningBodies"

$AdminAndGoverningBodiesURL = $rootSiteUrl + $AdminAndGoverningBodiesRelPath
$StrategicPlanningRelPath  = "AboutUs/StrategicPlanning"

$StrategicPlanningURL = $rootSiteUrl + $StrategicPlanningRelPath
$StrategicPlansRelPath = "AboutUs/StrategicPlanning/StrategicPlans"
$StrategicPlansURL = $rootSiteUrl + $StrategicPlansRelPath
$PoliciesAndGuidelinesRelPath = "AboutUs/PoliciesAndGuidelines"

$PoliciesAndGuidelinesURL = $rootSiteUrl + $PoliciesAndGuidelinesRelPath
$NewsAndEventsRelPath = "AboutUs/NewsAndEvents"

$NewsAndEventsURL = $rootSiteURL + $NewsAndEventsRelPath
$NewsAndHonoursRelPath = "AboutUs/NewsAndEvents/NewsAndHonours"
$NewsAndHonoursURL = $rootSiteUrl + $NewsAndHonoursRelPath

$AnnouncementsRelPath = "AboutUs/NewsAndEvents/Announcements"
$AnnouncementsURL = $rootSiteUrl + $AnnouncementsRelPath
$DatesAndDeadlinesRelPath = "AboutUs/NewsAndEvents/DatesAndDeadlines"
$DatesAndDeadlinesURL = $rootSiteUrl + $DatesAndDeadlinesRelPath
$ContactUsRelPath = "AboutUs/ContactUs"

$ContactUsURL = $rootSiteURL + $ContactUsRelPath
$DeansOfficeRelPath = "AboutUs/ContactUs/DeansOffice"
$DeansOfficeURL = $rootSiteUrl + $DeansOfficeRelPath
$ServicesAndResourcesRelPath = "ServicesAndResources"
$ServicesAndResourcesURL = $rootSiteUrl + $ServicesAndResourcesRelPath 
$FinanceRelPath = "ServicesAndResources/Finance"

$FinanceURL = $rootSiteUrl + $FinanceRelPath
$PurchasingRelPath = "ServicesAndResources/Purchasing"

$PurchasingURL = $rootSiteUrl + $PurchasingRelPath
$CommunicationsRelPath =  "ServicesAndResources/Communications"

$CommunicationsURL = $rootSiteUrl + $CommunicationsRelPath
$EventPromotionRelPath = "ServicesAndResources/Communications/EventPromotion"
$EventPromotionURL = $rootSiteURL + $EventPromotionRelPath
$FacilitiesRelPath = "ServicesAndResources/Facilities"
$FacilitiesURL = $rootSiteURL + $FacilitiesRelPath
$itRelPath = "ServicesAndResources/IT"
$itURL = $rootSiteUrl + $itRelPath
$hrRelPath = "HR"

$hrURL = $rootSiteUrl + $hrRelPath
$myHRstaffRelPath = "HR/myHRstaff"

$myHRstaffURL = $rootSiteUrl + $myHRstaffRelPath
$hiringStaffRelPath = "HR/hiringStaff"
$hiringStaffURL = $rootSiteUrl + $hiringStaffRelPath
$managingStaffRelPath = "HR/managingStaff"
$managingStaffURL = $rootSiteUrl + $managingStaffRelPath
$myHRfacultyRelPath = "HR/myHRfaculty"
$myHRfacultyURL = $rootSiteUrl + $myHRfacultyRelPath
$hiringFacultyRelPath = "HR/hiringFaculty"
$hiringFacultyURL = $rootSiteUrl + $hiringFacultyRelPath
$managingFacultyRelPath = "HR/managingFaculty"
$managingFacultyURL = $rootSiteUrl + $managingFacultyRelPath
$careerOpportunitiesRelPath = "HR/careerOpportunities"
$careerOpportunitiesURL = $rootSiteUrl + $careerOpportunitiesRelPath
$teamSitesRelPath = "TeamSites"
$teamSitesURL = $rootSiteUrl + $teamSitesRelPath
$teachingRelPath = "Teaching"
$teachingURL = $rootSiteUrl + $teachingRelPath
$researchRelPath = "Research"
$researchURL = $rootSiteUrl + $researchRelPath

