function OutputStartup {
    param($outputCSV, $directoryPath, $count, $assessmentType, $authType, $login)

	############ Display header information ################
	Write-Host "DataStrike Database Assessment via Powershell"
	Write-Host "Created by Nick Patti"
	Write-Host "Last modified 02/2025 by Nick Patti"
	Write-Host "Please be sure to update 'servers.txt' before starting."
	Write-Host "If you encounter errors, be sure you run Powershell as Administrator and set the Policy with the command ""Set-ExecutionPolicy RemoteSigned"". Refer to http://technet.microsoft.com/en-us/library/ee176961.aspx  "
	Write-Host "Refer to the Success.txt and Failures.txt logs when finished to see which servers completed and which failed."
	Write-Host "CSV Files will be placed in $outputCSV "
    Start-Sleep -s 5
	#########################################################

	#Let's give some info on where we are starting
	Write-Host ""
	Start-Sleep -s 1
	Write-Host "Working out of directory $directoryPath\"


	#display how many servers we will loop through
	Write-Host ""
	Start-Sleep -s 1
	Write-Host "We are doing $assessmentType assessments"
	Write-Host ""

	#display how many servers we will loop through
	Write-Host ""
	Start-Sleep -s 1
	Write-Host "Using Authentication: $authType "
	Write-Host ""


    if ($authType -eq "Windows"){
        #display how many servers we will loop through
    	Write-Host ""
    	Start-Sleep -s 1
    	Write-Host "WARNING - Using Windows Authentication of another user, will prevent queries running longer than 600 seconds. Any long running queries may need to be ran manually" -fore yellow -BackgroundColor darkblue
    	Write-Host ""
    }

    if ($authType -eq "Windows" -or $authType -eq "SQL"	){
        #display how many servers we will loop through
    	Write-Host ""
    	Start-Sleep -s 1
    	Write-Host "We are using credentials for: $login"
    	Write-Host ""
    }

    if ($trustType -eq "T" ){
        #display server certificate trusttype
    	Write-Host ""
    	Start-Sleep -s 1
    	Write-Host "We are using flag: -TrustServerCertificate"
    	Write-Host ""
    }

	#display how many servers we will loop through
	Write-Host ""
	Start-Sleep -s 1
	Write-Host "By my count, we have $count servers to process. Hang on to your seats!"
	Write-Host ""

    Start-Sleep -s 5
}