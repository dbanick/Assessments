function SetRunOptions{
	param($servers, $outputCSV, $extendedQueryTimeout)



	$Host.UI.RawUI.WindowTitle = "Database Assessment"
	#Clear-Host;
    Write-Host " -------------------------------------------------------------------------`r`n" 
    Write-Host " ************************* MSSQL Database Assessment *********************`r`n"
    Write-Host " -------------------------------------------------------------------------`r`n" 

    
    #Detect Login Type
    $loginChoices = [System.Management.Automation.Host.ChoiceDescription[]] @("&Trusted", "&Other Windows Login", "&SQL Login")
    $loginChoice = $host.UI.PromptForChoice('', 'Choose login type for instance', $loginChoices, 0)
    switch($loginChoice)
    {
        0 {
            $authType = "Trusted"
            $login = "$env:userdomain\$env:username"
            $securePassword =  ConvertTo-SecureString "PlaceholderFAKEPass" -AsPlainText -Force #populate with a fake password just so variable is in secure string format
            $password = ""
            $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $login, $securepassword #fake credential so variable will always be in credential format
          }
        1 { 
            $authType = "Windows"
            $login          = Read-Host -Prompt "Enter Windows Login (domain\username)"
            $securePassword = Read-Host -Prompt "Enter Password" -AsSecureString
            $password       = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
            $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $login, $securepassword
        }
        2 { 
            $authType = "SQL"
            $login          = Read-Host -Prompt "Enter SQL Login"
            $securePassword = Read-Host -Prompt "Enter Password" -AsSecureString
            $password       = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
            $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $login, $securepassword
        }
    }
    Write-host "Using authenication $authType"  -fore White -back Gray
    Write-host "Using username: $login"  -fore White -back Gray
	Write-Host "-------------------------------------------------------------------------" -fore white
	Write-Host ""
	Write-Host ""
	Write-Host ""
  
    #Trust Server Certificate
    Write-host  "Choose whether the connection should Trust the Server Certificate (invoke-sqlcmd option -TrustServerCertificate). You may need to change depending on whether the connections are encrypted `n`r"  -fore White 
    Write-host  "Enter T For Trusting the certificate `n`r"  -fore gray
    Write-host  "Enter U for Untrusted connection `n`r"  -fore gray 
    Write-Host "-------------------------------------------------------------------------" -fore white
    $TrustTypeInput  = Read-Host "Please enter your choice for certificate trust type(T, U); you can also hit <ENTER> to default Untrusted"

    IF ($TrustTypeInput  -eq "" -or $TrustTypeInput -ne "T") {$TrustTypeInput = "U"
        Write-host "Using Trust Type: Untrusted `n`r" -Fore white -back Gray}
    ELSE { $TrustTypeInput = "T"
            Write-host "Using Trust Type: Trusted `n`r" -Fore white -back Gray}
    

	#display server list
	Write-host  "Here are the servers that will be assessed. If you want to change this, please update servers.txt with the correct server list before continuing. `n`r"  -fore White 
	Write-host  "The text file will be reloaded after this prompt `n`r"  -fore White 
	Get-Content $servers | write-host -fore gray 
	Write-Host "-------------------------------------------------------------------------" -fore white
    Read-Host "When ready, press <ENTER> to continue"
    Write-host "Using server list: `n`r"  -fore White -back Gray
    Get-Content $servers | write-host -Fore white -back Gray 
	Write-Host "-------------------------------------------------------------------------" -fore white
	Write-Host ""
	Write-Host ""
	Write-Host ""

    #display CSV output
	Write-host  "The output path for the CSV files is: $outputCSV `n`r"  -fore White -back DarkBlue  
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
    Write-host  "If you change this to a higher number, you should be watching the server while this runs to ensure it does not cause problems. `n`r"  -fore Yellow -back DarkBlue
    Write-Host "-------------------------------------------------------------------------" -fore white
    $extendedQueryTimeoutInput = Read-Host "Hit <ENTER> to continue, or specify a new timeout in seconds (0 for unlimited, 600 = 10 minutes, etc)"
    Write-Host "-------------------------------------------------------------------------" -fore white
    Write-Host ""
    
    IF ($extendedQueryTimeoutInput -ne "" -and $extendedQueryTimeoutInput -match "^[\d\.]+$"){$extendedQueryTimeout = $extendedQueryTimeoutInput}
    IF ($extendedQueryTimeout -lt 0){$extendedQueryTimeout = 360}

    Write-host "Using Timeout Setting: `n`r"  -fore White -back Gray
    $extendedQueryTimeout | write-host -Fore white -back Gray
    Write-Host "-------------------------------------------------------------------------" -fore white
    Write-Host ""
    Write-Host ""
    Write-Host ""    	

	#Get Assessment Type
    Write-host  "Please Choose Below Option For MSSQL Server Report Generation `n`r"  -fore White 
    Write-host  "Enter 1 For FULL Assessment `n`r"  -fore gray
    Write-host  "Enter 2 for PERFORMANCE Assessment `n`r"  -fore gray 
    Write-host  "Enter 3 for MINI Assessment `n`r"  -fore gray 
    Write-host  "Enter 4 for CONFIGURATION Assessment `n`r"  -fore gray 
    Write-host  "Enter 5 for CUSTOM Assessment `n`r"  -fore gray 
    Write-host  "Enter 6 for SECURITY Assessment `n`r"  -fore gray 
    Write-host  "Enter 7 for CYBER_HYGIENE Assessment `n`r"  -fore gray 
    Write-host  "Enter 8 for RDS Assessment `n`r"  -fore gray 
    Write-Host "-------------------------------------------------------------------------" -fore white
    $AssessmentTypeInput  = Read-Host "Please enter your choice for Report Generation (1/2/3/4/5/6/7/8); you can also hit <ENTER> to default to FULL assessment"

    IF ($AssessmentTypeInput -eq "" -or $AssessmentTypeInput -notmatch "^[\d\.]+$" -or $AssessmentTypeInput -gt 8 -or $AssessmentTypeInput -lt 1){$AssessmentTypeInput = 1}
    Write-host "Using Assessment Type: `n`r" -Fore white -back Gray
    if ($AssessmentTypeInput -eq '1') {$assessmentType = "FULL"	
        Write-Host -Fore white -back Gray  “FULL assessment"}
    if ($AssessmentTypeInput -eq '2') {$assessmentType = "PERF"	
        Write-Host -Fore white -back Gray  “PERFORMANCE assessment"}
    if ($AssessmentTypeInput -eq '3') {$assessmentType = "MINI"	
        Write-Host -Fore white -back Gray  “MINI assessment"}
    if ($AssessmentTypeInput -eq '4') {$assessmentType = "CONFIG"	
        Write-Host -Fore white -back Gray  “CONFIG assessment"}
    if ($AssessmentTypeInput -eq '5') {$assessmentType = "CUSTOM"	
        Write-Host -Fore white -back Gray “CUSTOM assessment"}
    if ($AssessmentTypeInput -eq '6') {$assessmentType = "SECURITY"	
        Write-Host -Fore white -back Gray “SECURITY assessment"}
    if ($AssessmentTypeInput -eq '7') {$assessmentType = "CYBER_HYGIENE"	
        Write-Host -Fore white -back Gray “CYBER_HYGIENE assessment"}
    if ($AssessmentTypeInput -eq '8') {$assessmentType = "RDS"	
        Write-Host -Fore white -back Gray “RDS assessment"}
    Write-Host "-------------------------------------------------------------------------" -fore white
    Write-Host ""
    Write-Host ""
    Write-Host ""  

<#
    Write-host "*******Do You want EZMODE? *******`n`r"  -fore White -back Gray
    Write-host  "Enter 1 For EZMODE (BETA*) `n`r"  -fore gray

    Write-Host "-------------------------------------------------------------------------" -fore white
    $ezmode = Read-Host "*******Do You want to try our EZDBA? Enter 1 for Yes *******"
    Write-Host "-------------------------------------------------------------------------" -fore white
    IF ($ezmode -eq "" -or $ezmode -notmatch "^[\d\.]+$" -or $ezmode -gt 2 -or $ezmode -lt 1){$ezmode = 1}
#>
    return $assessmentType, $extendedQueryTimeout, $outputCSV, $authType, $loginChoice, $login, $password, $securePassword, $credential, $TrustTypeInput
}