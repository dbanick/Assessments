function LogScriptStatus{
	param($instance, $LogPath, $qname, $status, $meta)

	$DateTime = Get-Date

	New-Object -TypeName PSCustomObject -Property @{
        Servername = $instance 
        DataType = $status 
        Value = $qname
    } | export-csv $meta -NoTypeInformation -append

    #create log files if needed
    if((test-path $LogPath\Success.txt) -eq $false){echo "" | Out-File $LogPath\Success.txt}
    if((test-path $LogPath\Failures.txt) -eq $false){echo "" | Out-File $LogPath\Failures.txt}

	if ($status -eq "FailedScript"){

		Write-Host ""
		Write-Host -Fore Red "Something went wrong with the query against $instance , query file $qname ..."
		Write-Host ""
					
		echo "Instance $instance encountered an error on $DateTime for query $qname . Please verify connectivity before rerunning, and attempt running script manually." | Out-File $LogPath\Failures.txt -append
		echo " " | Out-File $LogPath\Failures.txt -append
	}
}