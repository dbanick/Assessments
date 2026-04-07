function SetRERunOptions{
	param($outputCSV, $extendedQueryTimeout)



	$Host.UI.RawUI.WindowTitle = "Database Assessment"
	Clear-Host;
    Write-Host " -------------------------------------------------------------------------`r`n" 
    Write-Host " ***************** MSSQL Database Assessment RERUN *********************`r`n"
    Write-Host " -------------------------------------------------------------------------`r`n" 
  

    #display CSV output
	Write-host  "The path for the CSV files we are checking is: $outputCSV `n`r"  -fore White -back DarkBlue  
    Write-Host "-------------------------------------------------------------------------" -fore white
    $outputCSVInput = Read-Host "Hit <ENTER> to continue, or specify a location"
    Write-Host "-------------------------------------------------------------------------" -fore white
    Write-Host ""
 
    IF ($outputCSVInput -ne "") {
        IF ((test-path $outputCSVInput) -eq $true){$outputCSV = $outputCSVInput}
        ELSE {
            Write-Host "Path $outputCSVInput does not exist; reverting to default path" -fore white -back Red
            Write-Host "To re-enter, exit the script and run again" -fore white -back Red
            }
    }
    Write-host "Using CSV location: `n`r"  -fore White -back Gray
    $outputCSV | write-host -Fore white -back Gray
    Write-Host "-------------------------------------------------------------------------" -fore white
    Write-Host ""
    Write-Host ""
    Write-Host ""
    
	#Display timeout setting
	Write-host  "The extended timeout setting is set to $extendedQueryTimeout seconds; this is the max amount of time that a query will run in this script. `n`r"  -fore White -back DarkBlue  
    Write-host  "You SHOULD be watching the server while this runs to ensure it does not cause problems. `n`r"  -fore Yellow -back DarkBlue
    Write-Host "-------------------------------------------------------------------------" -fore white
    $extendedQueryTimeoutInput = Read-Host "Hit <ENTER> to continue, or specify a new timeout in seconds (0 for unlimited, 600 = 10 minutes, etc)"
    Write-Host "-------------------------------------------------------------------------" -fore white
    Write-Host ""
    
    IF ($extendedQueryTimeoutInput -ne "" -and $extendedQueryTimeoutInput -match "^[\d\.]+$"){$extendedQueryTimeout = $extendedQueryTimeoutInput}
    IF ($extendedQueryTimeout -lt 0){$extendedQueryTimeout = 0}

    Write-host "Using Timeout Setting: `n`r"  -fore White -back Gray
    $extendedQueryTimeout | write-host -Fore white -back Gray
    Write-Host "-------------------------------------------------------------------------" -fore white
    Write-Host ""
    Write-Host ""
    Write-Host ""    	

	

    return $extendedQueryTimeout, $outputCSV
}