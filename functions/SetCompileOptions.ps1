function SetCompileOptions{
	param($tables, $outputName, $outputCSV)

    #Find Folders to process
    $files = Get-ChildItem $outputCSV 
    #Verify they are actually folders
    $folders = $files | where-object { $_.PSIsContainer }


	$Host.UI.RawUI.WindowTitle = "Database Assessment Assessment"
	#Clear-Host;
    Write-Host " -------------------------------------------------------------------------`r`n" 
    Write-Host " **************** MSSQL Database Assessment Compilation ******************`r`n"
    Write-Host " -------------------------------------------------------------------------`r`n" 
  
    #####################################
	#display folder list
	Write-host  "Here are the folders that will be compiled. If you need to upload folders, please do so now before continuing. `n`r"  -fore White 
	Write-host  "The list of folders will be reloaded after this prompt `n`r"  -fore White 
	$folders.Name | write-host -fore gray 
	Write-Host "-------------------------------------------------------------------------" -fore white
    Read-Host "When ready, press <ENTER> to continue"

    #Find Folders to process
    $files = Get-ChildItem $outputCSV 
    #Verify they are actually folders
    $folders = $files | where-object { $_.PSIsContainer }

    Write-host "Using server list: `n`r"  -fore White -back Gray
    $folders.Name | write-host -Fore white -back Gray 
	Write-Host "-------------------------------------------------------------------------" -fore white
	Write-Host ""
	Write-Host ""
	Write-Host ""

    #####################################
    #display naming convention
	Write-host  "The output file name will start with: $outputName `n`r"  -fore White -back DarkBlue  
    Write-Host "-------------------------------------------------------------------------" -fore white
    $outputNameInput = Read-Host "Hit <ENTER> to continue, or specify a new naming format"
    Write-Host "-------------------------------------------------------------------------" -fore white
    Write-Host ""
 
    IF ($outputNameInput -ne "" -and $outputNameInput.Length -gt 2) {$outputName = $outputNameInput}

    Write-host "Using naming convention: `n`r"  -fore White -back Gray
    $outputName | write-host -Fore white -back Gray
    Write-Host "-------------------------------------------------------------------------" -fore white
    Write-Host ""
    Write-Host ""
    Write-Host ""
    
    #####################################
	#Use Tables in Excel
	Write-host  "Do you want the spreadsheet to be formatted as a table (default is yes) `n`r"  -fore White -back DarkBlue  
    Write-Host "-------------------------------------------------------------------------" -fore white
    $tableInput = Read-Host "Type 'N' for No, or just hit <ENTER> to accept default of Yes"
    Write-Host "-------------------------------------------------------------------------" -fore white
    Write-Host ""
    
    IF ($tableInput -eq "N" -or $tableInput -eq "No"){$tables = 0}

    Write-host "Using Tables: `n`r"  -fore White -back Gray
    IF ($tables = 1){"YES"  | write-host -Fore white -back Gray}
    ELSE {"NO"  | write-host -Fore white -back Gray} 
    Write-Host "-------------------------------------------------------------------------" -fore white
    Write-Host ""
    Write-Host ""
    Write-Host ""    	
    start-sleep -s 1

    #####################################
    return $tables, $outputName
}