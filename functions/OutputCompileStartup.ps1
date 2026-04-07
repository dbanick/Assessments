 function OutputCompileStartup {
    param($compiledCSV, $processedCSV, $LogPath, $count)
    
    ############ Display header information ################
    Write-Host "DataStrike Assessment Compilation via Powershell"
    Write-Host "Created by Nick Patti"
    Write-Host "Last modified 02/2025 by Nick Patti"
    Write-Host "If you encounter errors, be sure you run Powershell as Administrator and set the Policy with the command ""Set-ExecutionPolicy RemoteSigned"". Refer to http://technet.microsoft.com/en-us/library/ee176961.aspx  "
    Start-Sleep -s 1
    Write-Host "Refer to the CompileSuccess.txt and CompileFailures.txt logs when finished to see which servers completed and which failed."
    Start-Sleep -s 1
    ########################################################


    #Let's give some info on where we are starting
    Write-Host ""
    Start-Sleep -s 1
    Write-Host "Working out of directory $directoryPath\"
    
    ############ Display header information ################
    Write-Host ""
    Start-Sleep -s 1
    Write-Host "When finished, the compiled spreadsheets will be sent to $compiledCSV"
    Write-Host "And the processed CSV's will be sent to $processedCSV"
    Write-Host "The error logs will be written to $LogPath"
    
    #Let's let everyone know how much work we have to do
    Write-Host ""
    Start-Sleep -s 1
    Write-Host "By my count, we have $count folders to process. Hang on to your seats!"
    Write-Host ""
}