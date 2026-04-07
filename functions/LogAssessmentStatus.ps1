function LogAssessmentStatus{
	param($instance, $LogPath, $status)

	$DateTime = Get-Date

    #create log files if needed
    if((test-path $LogPath\CSVSuccess.txt) -eq $false){echo "" | Out-File $LogPath\CSVSuccess.txt}
    if((test-path $LogPath\CSVFailures.txt) -eq $false){echo "" | Out-File $LogPath\CSVFailures.txt}

	if ($status -eq "Success"){
		Write-Host ""
		Write-Host -Fore Green “Assessment on $instance has completed successfully”
		Write-Host ""
			
		echo "Instance $instance discovery completed successfully on $DateTime." | Out-File $LogPath\CSVSuccess.txt -append
		echo " " | Out-File $LogPath\CSVSuccess.txt -append
	} else {
		Write-Host ""
		Write-Host -Fore Red "Something went wrong with the assessment on $instance ..."
		Write-Host ""

		echo "Instance $instance encountered an error on $DateTime. Please verify connectivity before rerunning." | Out-File $LogPath\CSVFailures.txt -append
		echo " " | Out-File $LogPath\CSVFailures.txt -append
    }
}

