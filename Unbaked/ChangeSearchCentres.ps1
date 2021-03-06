$webApplicationUrl = "http://committees.fomiuat.med.ubc.ca"
$searchCentrePath = "/searchctr/"
$resultsPage = "Pages/results.aspx"

# Site Collection Search Center URL
$searchURL = $webApplicationUrl + $searchCentrePath

# Site Collection Search Dropdown Mode Codes:
#
# NO NEED TO SPECIFY SEARCH RESULTS PAGE
# HideScopeDD - Do Not Show Scopes Dropdown, and default to target results page
# ShowDD_NoContextual - Show, do not include contextual scopes
# ShowDD_NoContextual_DefaultURL - Show, do not include contextual scopes, and default to 's' URL parameter
#
# NEED TO SPECIFY SEARCH RESULTS PAGE
# HideScopeDD_DefaultContextual - Do Not Show Scopes Dropdown, and default to contextual scope
# ShowDD_DefaultContextual - Show and default to contextual scope
# ShowDD - Show scopes Dropdown
# ShowDD_DefaultURL - ShowDD_DefaultURL
#
$searchDDMode = "ShowDD"

# Site Collection Search Results Page
$searchResultsP = $searchUrl + $resultsPage

# Get the Web Application
$webApplication = Get-SPWebApplication $webApplicationUrl

# loop through the sites in the web application
foreach ($site in $webApplication.Sites)
{
      # Get the root web
      $web = $site.RootWeb
      # We want to update all sites that are not a search center
      if ($web.WebTemplate -ne "SRCHCEN")
      {
         # Site Collection Search Center
         $web.AllProperties["SRCH_ENH_FTR_URL"] = $searchURL

         # Site Collection Search Dropdown Mode
         $web.AllProperties["SRCH_SITE_DROPDOWN_MODE"] = $searchDDMode

         # Site Collection Search Results Page - UNCOMMENT NEXT LINE IF USING ONE OF THE "Need to specify search results page" SEARCH MODES ABOVE
         $web.AllProperties["SRCH_TRAGET_RESULTS_PAGE"] = $searchResultsP

         $web.Update()

         Write-Host "Updated Search Settings on Site Collection: " $web.Url

      }
}