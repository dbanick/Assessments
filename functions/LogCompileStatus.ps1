function LogCompileStatus{
	param($workingFolderFriendly, $LogPath, $status)

	$DateTime = Get-Date

	if ($status -eq "Failed"){
    	Write-Host ""
	    Write-Host -Fore Red "Something went wrong with the conversion on $workingFolderFriendly ..."
		Write-Host ""
		echo "Folder $workingFolderFriendly encountered an error on $DateTime. Please review before rerunning." | Out-File $LogPath\CompileFailures.txt -append
		echo " " | Out-File $LogPath\CompileFailures.txt -append
	} else {
		echo "Folder $workingFolderFriendly assessment completed successfully on $DateTime." | Out-File $LogPath\CompileSuccess.txt -append
		echo " " | Out-File $LogPath\CompileSuccess.txt -append
    }
}
