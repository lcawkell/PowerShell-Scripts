
        ##############################
        #### SharePoint DB Health ####
        ##############################

$dateStamp = get-date -uformat "%Y-%m-%d@%H-%M-%S"
$filePath = "C:\MedNetOps\DBHealth\"
$fileName = "Ops-Task_SP-DB-Health"
$fileExt = ".txt"
$file = $filePath + $fileName + "-" + $dateStamp + $fileExt

# if folder does not exist...
if (!(Test-Path $filePath)) {
# create it
[void](new-item $filePath -itemType directory)
}


$stream = [System.IO.StreamWriter] $file

$stream.WriteLine("<b><font color=#FF0000>Red</b> is a warning</font><br/>")
$stream.WriteLine("<b><font color=#FFE000>Yellow</b> is a note</font><br/>")
$stream.WriteLine("<b><font color=#008000>Green</b> means All Good</font><br/><br/><br/>")


foreach ($app in Get-SPWebApplication)
{
    $appNameCount = $app.DisplayName.Length
    $formatter = ""
    for($i=0;$i -lt $appNameCount+2;$i++)
    {
    
        $formatter = $formatter + "#"
    
    }
    
    Write-Host $formatter
    $stream.WriteLine($formatter + "<br/>")
    Write-Host  $app.DisplayName
    $stream.WriteLine(" " + $app.DisplayName + "<br/>")
    Write-Host $formatter
    $stream.WriteLine($formatter + "<br/>")
    Write-Host 
    $stream.WriteLine("<br/>")
    foreach($contentdb in $app.ContentDatabases)
    {
        Write-Host ContentDB: $contentdb.DisplayName
        $stream.WriteLine("<b>ContentDB:</b> " + $contentdb.DisplayName + "<br/>")
        $diskSize = $contentdb.disksizerequired / 1000000000
        $diskSizeF = "{0:N3}" -f $diskSize
        
        
        ############################
        #### Content DB Storage ####
        ############################
        
        
        if($contentdb.disksizerequired -gt 100000000000) ## NOTE
        {
            if($contentdb.disksizerequired -gt 180000000000) ## WARNING
            {
                $fontColor = "#FF0000" #Red
                Write-Host Size: ${diskSizeF}gb / 200gb
                $stream.WriteLine("<b>Size:</b> <font color=" + $fontColor + ">" +${diskSizeF}+"gb / 200gb</font>" + "<br/>")
            }
            else
            {
                $fontColor = "#FFE000" #Yellow
                Write-Host Size: ${diskSizeF}gb / 200gb
                $stream.WriteLine("<b>Size:</b> <font color=" + $fontColor + ">" +${diskSizeF}+"gb / 200gb</font>" + "<br/>")       
            }
        }
        else
        {
            $fontColor = "#008000" #Green
            Write-Host Size: ${diskSizeF}gb / 200gb
            $stream.WriteLine("<b>Size:</b> <font color=" + $fontColor + ">" +${diskSizeF}+"gb / 200gb</font>" + "<br/>")      
        }
        
        
        ##########################
        #### Content DB Sites ####
        ##########################
        
        
        if($contentdb.CurrentSiteCount -gt ($contentdb.MaximumSiteCount*.5)) ## NOTE
        {
            if($contentdb.CurrentSiteCount -gt ($contentdb.MaximumSiteCount*.9)) ## WARNING
            {
                $fontColor = "#FF0000" #Red
                Write-Host Site Collections: $contentdb.CurrentSiteCount / $contentdb.MaximumSiteCount
                $stream.WriteLine("<b>Site Collections:</b> <font color=" + $fontColor + ">" + $contentdb.CurrentSiteCount+" / "+$contentdb.MaximumSiteCount + "</font>" + "<br/>")
            }
            else
            {
                $fontColor = "#FFE000" #Yellow
                Write-Host Site Collections: $contentdb.CurrentSiteCount / $contentdb.MaximumSiteCount
                $stream.WriteLine("<b>Site Collections:</b> <font color=" + $fontColor + ">" + $contentdb.CurrentSiteCount+" / "+$contentdb.MaximumSiteCount + "</font>" + "<br/>")
            }
        }
        else ## ALL GOOD
        {
            $fontColor = "#008000" #Green
            Write-Host Site Collections: $contentdb.CurrentSiteCount / $contentdb.MaximumSiteCount
            $stream.WriteLine("<b>Site Collections:</b> <font color=" + $fontColor + ">" + $contentdb.CurrentSiteCount+" / "+$contentdb.MaximumSiteCount + "</font>" + "<br/>")
        }


        ###############################
        #### Site Collection Stats ####
        ###############################
        
        $sites = Get-SPSite -Limit ALL -ContentDatabase $contentdb | Sort-Object -Descending {$_.usage.storage}
        Write-Host 
        $stream.WriteLine("<br/>")
        foreach($site in $sites)
        {
            $name = $site.RootWeb.title
            $url = $site.url
            $storage = "{0:N1}" -f ($site.usage.storage/1000000)

            if($site.usage.storage -gt 100000000)
            {
                if($site.usage.storage -gt 1000000000)
                {
                    if($site.usage.storage -gt 10000000000)
                    {
                        $fontColor = "#FF0000" #Red
                        $siteName = "<b>Name:</b> "+$name
                        $siteStorage = "<b>Storage:</b> <font color=" + $fontColor + ">" +$storage+"MB" + "</font>"
                        Write-Host $siteName
                        $stream.WriteLine($siteName + "<br/>")
                        Write-Host $siteStorage
                        $stream.WriteLine($siteStorage + "<br/>")
                    }
                    else
                    {
                        $fontColor = "#FFE000" #Yellow
                        $siteName = "<b>Name:</b> "+$name
                        $siteStorage = "<b>Storage:</b> <font color=" + $fontColor + ">" +$storage+"MB" + "</font>"
                        Write-Host $siteName
                        $stream.WriteLine($siteName + "<br/>")
                        Write-Host $siteStorage
                        $stream.WriteLine($siteStorage + "<br/>")
                    }
                }
                else
                {
                    $fontColor = "#008000" #Green
                    $siteName = "<b>Name:</b> " + $name
                    $siteStorage = "<b>Storage:</b> <font color=" + $fontColor + ">" +$storage+"MB" + "</font>"
                    Write-Host $siteName
                    $stream.WriteLine($siteName + "<br/>")
                    Write-Host $siteStorage
                    $stream.WriteLine($siteStorage + "<br/>")
                }
            }
        }
        

        
    Write-Host 
    $stream.WriteLine("<br/>")
    }
    Write-Host 
    $stream.WriteLine("<br/>")
}

$stream.close()