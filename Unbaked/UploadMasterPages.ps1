param($collectionUrl)

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Sharepoint")
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Sharepoint.Administration")

$checkInComment="Check In"
$publishComment="published"
$approveComment="Approved"
$logfile = "UploadMasterPage_$(get-date -f yyyyMMdd_hhmmss).log"
$spsite = new-object Microsoft.Sharepoint.SPSite($collectionUrl);
$web = $spsite.RootWeb;
 
    $masterPageList = ($web).GetFolder("Master Page Gallery")
    # Get file system path
$filesfolde = Split-Path $script:MyInvocation.MyCommand.Path

$masterPageLocalDir = $filesfolde + "\Docs"
    #For upload all files in document library from file system
foreach ($file in Get-ChildItem $masterPageLocalDir)
	{
	$web.AllowUnsafeUpdates=$true;
try
{
	if ([Microsoft.SharePoint.Publishing.PublishingSite]::IsPublishingSite($spsite)) 
	{
	
	   $stream = [IO.File]::OpenRead($file.fullname)
       $destUrl = $web.Url + "/_catalogs/masterpage/" + $file.Name;
	   $masterPageFile=$web.GetFile($destUrl)
	   #write-host($masterPageFile)
       
       if($masterPageFile.CheckOutStatus -ne "None")
	   {		
    		#$web.AllowUnsafeUpdates  = $true;
			$masterPageList.files.Add($destUrl,$stream,$true)				
			
			$stream.close()						
			$masterPageFile.CheckIn($checkInComment);						
			$masterPageFile.Publish($publishComment);				
			$masterPageFile.Approve($approveComment);
			$masterPageFile.Update();         
 	  	    $web.Update();
		    $web.AllowUnsafeUpdates  = $false;
		    $outputText = $file.Name+ " Master Page uploaded on $web site"
   			write-output $outputText
   			write-output $outputText |  out-File $logfile -Append
		}
	    else
		{
 		     $masterPageFile.CheckOut();
			 try{
				 $masterPageList.Files.Add($destUrl,$stream,$true)
			 }
			 catch
			 {
				 write-Output $_
			 }
			 $stream.close()							  
			 $masterPageFile.CheckIn($checkInComment);						  
			 $masterPageFile.Publish($publishComment);						  
			 $masterPageFile.Approve($approveComment);
			 $masterPageFile.Update();         
         	 $web.Update();
        	 $web.AllowUnsafeUpdates  = $false;
        	 $outputText = $file.Name +  " Master Page uploaded on $web site"
       		 write-output $outputText
       		 write-output $outputText |  out-File $logfile -Append
		}
    }
	
	else
	{
	
		$stream = [IO.File]::OpenRead($file.fullname)
       	$destUrl = $web.Url + "/_catalogs/masterpage/" +$file.Name
		$masterPageFile=$web.GetFile($destUrl)
     	if($masterPageFile.CheckOutStatus -ne "None")
		{
			$masterPageList.Files.Add($destUrl,$stream,$true)
			$stream.close()						
			$masterPageFile.CheckIn($checkInComment);						
		    $masterPageFile.Publish($publishComment);				
			$masterPageFile.Approve($approveComment);
			$masterPageFile.Update();         
         	$web.Update();
        	$web.AllowUnsafeUpdates  = $false;
        	$outputText = $file.Name +  "Master Page uploaded on $web site"
       		write-output $outputText
       		write-output $outputText |  out-File $logfile -Append
		}
	    else
		{
 		    $masterPageFile.CheckOut();
			$masterPageList.Files.Add($destUrl,$stream,$true)
			$stream.close()							  
			$masterPageFile.CheckIn($checkInComment);						  
			$masterPageFile.Publish($publishComment);						  
			$masterPageFile.Approve($approveComment);
			$masterPageFile.Update();         
         	$web.Update();
        	$web.AllowUnsafeUpdates  = $false;
        	$outputText = $file.Name+ "Master Page uploaded on $web site"
       		write-output $outputText
       		write-output $outputText |  out-File $logfile -Append
		  }
   	}	
}
catch
{
try
	   {
	
		
		$stream = [IO.File]::OpenRead($file.fullname)
         	$destUrl = $web.Url + "/_catalogs/masterpage/" + $file.Name;
		$masterPageFile=$web.GetFile($destUrl)
          	 if($masterPageFile.CheckOutStatus -ne "None")
		   {
				$masterPageList.Files.Add($destUrl,$stream,$true)
				$stream.close()						
				$masterPageFile.CheckIn($checkInComment);
 				$masterPageFile.Update();         
         			 $web.Update();
        			  $web.AllowUnsafeUpdates  = $false;
        			  $outputText = $file.Name+ " Master Page uploaded on $web site"
       				  write-output $outputText
       				  write-output $outputText |  out-File $logfile -Append
		   }
		  else
		    {

 				 $masterPageFile.CheckOut();
				$masterPageList.Files.Add($destUrl,$stream,$true)
				$stream.close()						
				$masterPageFile.CheckIn($checkInComment);
 				$masterPageFile.Update();         
         			 $web.Update();
        			  $web.AllowUnsafeUpdates  = $false;
        			  $outputText = $file.Name +" Master Page uploaded on $web site"
       				  write-output $outputText
       				  write-output $outputText |  out-File $logfile -Append
		   }
	   }
	catch
	   {
		write-Output $_ | out-File $logfile -Append
	   }	 
}
}
$web.dispose();
$spsite.dispose();
