function GenerateMetaData{
	param($instance, $outputFolder, $version, $assessmentType, $scriptPath, $LogPath)

    if ($version -eq $null) {Write-Host -Fore Red "Assessment for $instance will be terminating"} else {

	    #Output working instance
	    Write-Host "Working on instance: $instance"
	    Write-Host "Output folder is: $outputFolder"
	    Write-Host "The instance version is : $version"
        Write-Host "We are performing a $assessmentType assessment"
	    Write-Host ""
    
	    #Loop through scripts
	    Write-Host "Executing scripts from: $scriptPath"
	    Write-Host "Log files are being written to $LogPath"
	    Write-Host ""

	    $meta = $outputFolder +"000_META.csv" 
            
	    New-Object -TypeName PSCustomObject -Property @{
	    	Servername = $instance
	    	DataType = "Version"
	    	Value = $version
	    } | export-csv $meta -NoTypeInformation

	    New-Object -TypeName PSCustomObject -Property @{
            Servername = $instance 
            DataType = "AssessmentType" 
            Value = $assessmentType
        } | export-csv $meta -NoTypeInformation -append


    }
    return $meta
}