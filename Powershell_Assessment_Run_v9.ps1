######################################
# Assessment Powershell Script       #
############################################
# Created 03/14/2017                       #
# By: Nick Patti                           #
########################################################################################
# This Powershell script calls all the scripts within the SQL_Scripts folder	       #
# Runs each script against each server                                                 #
# Generates a seperate output folder for each server                                   #
# Saves the output as a .csv file                                                      #
# There is another script that will compile the output into an spreadsheet per server  #
########################################################################################
############################## Change Control ##########################################
# Version 2.0                                                                          #
# Date:   09/06/2017                                                                   #
# Modified By: Nick Patti                                                              #
# Change Log:                                                                          #
#  1. Added logic to determine the version of SQL and then run the appropriate scripts #
#     This works for SQL 2005 - 2012. 2014 scripts still need to be seperated          #
#  2. Added scripts for SQL 2000 to perform a lite assessment                          #
#                                                                                      #
# Version 3.0                                                                          #
# Date:   04/2020                                                                      #
# Modified By: Nick Patti                                                              #
# Change Log:                                                                          #
#  1. Added support for SQL 2014 - 2019                                                #
#  2. Changed locations to relative paths to be location independent                   #
#                                                                                      #
# Version 4.0                                                                          #
# Date: 06/2020                                                                        #
# Modified By: Nick Patti                                                              #
#  1. Added scripts for 2014 - 2019								                       #
#  2. Added server logging data to capture version and any failed/ timed out queries   #
#  3. Created functions for various tasks to make script more modular				   #
#  4. Changed the SQL method to invoke-sqlcmd2 to allow unlimited query timeouts	   #
#                                                                                      #
#Version 5.0                                                                           #
#Date 09/2020                                                                          #
#Modified By: Nick Patti                                                               #
#  1. Provided options for different assessment types                              	   #
#  2. Input variables are now more user friendly                              		   #
#  3. Added progress bar                              			 					   #
#  4. Built arrays to determine which scripts to run                              	   #
#  5. Changed logic on when to call invoke-sqlcmd2 vs invoke-sqlcmd                    #
#      There is heavier weight towards invoke-sqlcmd	                               #
#                                                                                      # 
#Version 6.0                                                                           #
#Date 12/2020                                                                          #
#Modified By: Nick Patti                                                               #
#  1. Internal version - not released publicly                              		   #
#  2. Fixed issue with output folder creation                              		       #
#  3. Streamlined RunOptions								                           #
#                                                                                      # 
#Version 7.0                                                                           #
#Date 02/2022                                                                          #
#Modified By: Nick Patti & Josh Washer                                                 #
#  1. Added option to use SQL Auth                              					   #
#  2. Added option for Another Windows user                              			   #
#  3. Add sp_configure and other scripts to PERF assessment config                     #
#  4. Added RDS option                              			 				       #
#  5. Laid Groundwork for EZ-DBA Recommendations                                       #
#     (allowed option but EZDBA is still WIP)		                                   #
#  6. Added support for SQL 2022						      			               #
#                                                                                      #
#Version 8.0                                                                           #
#Date 01/2024                                                                          #
#Modified By: Nick Patti & Josh Washer                                          	   #
#  1. Several bug fixes                             					               #
#  2. Some authentication errors have been fixed                              		   #
#  3. Added option to -TrustServerCertificate for encrypted connections.               #
#          This option is to resolve error                                             #
#          "provider: SSL Provider, error: 0 – The certificate chain was issued by an authority that is not trusted." 
#          This is only available in v22 of invoke-sqlcmd                              #
#          Run this command to check your version of invoke-sqlcmd:                    #
#                (Get-Command Invoke-SqlCmd).Module                                    #
#          To upgrade invoke-sqlcmd run this command:                                  #
#                 Install-Module -Force SqlServer                                      #
#  4. Updated SQL scripts                                                              #
#                                                                                      #
#
#Version 9.0                                                                           #
#Date 02/2025                                                                          #
#Modified By: Nick Patti & Josh Washer                                          	   #
#  1. Fixed issue with test connection to allow localhost 
#  2. Fixed relative pathing
#  3. Fixed issue with assessment types (full vs security etc)
#  4. Updated / added SQL scripts      
#        010 - Updated instant file initialization check to query table instead of WMI
#        045 - Updated script to show volume info
#        065 - Updated table record count to also show total table size for context
#        120 - Checks if tempdb is right sized
#        121 - Checks the power plan settings of server ** Note - this may only work if you run PS from the server you are assessing**
#        122 - Returns the Query Store settings of databases
#        123 - Returns any forced or otherwise notable plans saved in Query Store
#        199 - added sp_Blitz logic (without creating the SP) to give a very basic summary of some findings; not to be totally relied on
#
#  9.1 : bug fixes
#  9.2 : bug fixes
#  9.3 : Modified by Lucja Dolega - updated compile table style to Medium 21 in ConvertCSV-ToExcel_Tables to work better with highlighting
#        Modified 022 script - added cast as datetime for a few columns; NP
#  9.4 : Modifed 123 QS script to work correctly for 2016-2019 versions
#  9.5 : Added default parameter $defVersion so we can default to a version of SQL if the pre-check fails
#
########################################################################################


#determine the assessment folder based of where this is executed from; you can also explicitly define it here
$directoryPath = Split-Path $MyInvocation.MyCommand.Path
#$directoryPath = "C:\DataStrike\Database_Assessment_V8"

cd $directoryPath

cls

########DEFAULT VARIALBES#################
$outputStartup = 1 #1 = Display long startup with verbose output but takes 15 seconds longer
$prompt = 1 #0 = Do not prompt for input variables; #1 = prompt for input variables
$extendedQueryTimeout = 900 #how long the slow queries should run (seconds) before timing out
$queryTimeout = 180 #how long most queries should run
$outputCSV = "$directoryPath\CSV" #This should be set to where you want your CSV files to be dropped
$logPath = "$directoryPath\logs" #This should be set to where you want your log files to be dropped
$funcPath = "$directoryPath\functions" #This should be set to where you have your functions
$buildFile = "$directoryPath\SQLBuilds.csv" #File location for downloading list of SQL builds
$slowQuery = '15, 27, 29, 56, 57, 79, 91, 100, 102' #script number for queries that need a longer query timeout. 56 and 100 tend to run long; you can add others that need more than a minute
$defVersion = "2014" #If we can't determine the version, what should we default to? This is mainly for servers that require trust which our pre-check can't query
#$cancel = 1 #UNUSED
#########################################

#Load Functions and Assemblies
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
. .\functions\Invoke-SqlCmd2.ps1 #used to call queries against SQL IF the timeout is over the allowable limit for invoke-sqlcmd
. .\functions\GetSQLVersion.ps1 #determine version of SQL to run and set variable
. .\functions\OutputStartup.ps1 #write output to cmd prompt
. .\functions\OutputSummary.ps1 #write output to cmd prompt
. .\functions\GenerateMetaData.ps1 #creates the meta file (overwrites existing one if exists) and logs assessment type + version
. .\functions\LogScriptStatus.ps1 #log script failures
. .\functions\LogAssessmentStatus.ps1 #log overall assessment failures
. .\functions\SetRunOptions.ps1 #set default values and then allow overwrides through input
. .\functions\BuildScriptArray.ps1 #determines which scripts to run based on version and assessment type
. .\functions\Execute-Query.ps1 #wrapper for calling SQL commands; allows different authentication types
#. .\functions\EZDBA.ps1 #used to make DBA life EZ Mode


cd $directoryPath

#Begin TRY/CATCH to add snap-ins if needed
TRY{
    .\functions\Initialize-SqlpsEnvironment.ps1
    Write-Host "Initializing Powershell"
} CATCH {Write-Host "Cannot add Windows PowerShell snap-in SqlServerCmdletSnapin100 because it is already added."}

if (!(Get-Module -ListAvailable -Name "SQLPS")) {    
    Write-Host -BackgroundColor Red -ForegroundColor White "Module Invoke-Sqlcmd is not loaded; you may need to run this manually:"
    Write-Host -BackgroundColor Red -ForegroundColor White "Install-module -Name SqlServer -Scope CurrentUser"
    Write-Host -BackgroundColor Red -ForegroundColor White "Import-Module Sqlps -DisableNameChecking;"
}


cd $directoryPath

#determine some initial variables based on where we are
$servers = Resolve-Path "servers.txt"


#Create folders if not exists
if(!(Test-Path -Path $outputCSV )) {New-Item -ItemType directory -Path $outputCSV | Out-Null }#main CSV folder
if(!(Test-Path -Path $LogPath )) {New-Item -ItemType directory -Path $LogPath | Out-Null} #folder for log files

#Get input from user / verify config
if($prompt -eq 1){
    $RunOptions = SetRunOptions $servers $outputCSV $extendedQueryTimeout
    $assessmentType = $RunOptions[1]
    $extendedQueryTimeout = $RunOptions[2]
    if ($RunOptions[3] -eq ""){$outputCSV = $RunOptions[3].Path} else {$outputCSV = $RunOptions[3]}
    if ($assessmentType -ne "SECURITY" -and $assessmentType -ne "CYBER_HYGIENE"){$scriptPath_base = Resolve-Path ".\SQL_Scripts\Database_Assessment"} 
    if ($assessmentType -eq "SECURITY"){$scriptPath_base = Resolve-Path ".\SQL_Scripts\Security_Assessment"} 
    if ($assessmentType -eq "CYBER_HYGIENE"){$scriptPath_base = Resolve-Path ".\SQL_Scripts\CYBER_HYGIENE_Assessment"}
    $authType = $RunOptions[4]
    $loginChoice = $RunOptions[5]
    $username = $RunOptions[6]
    $password = $RunOptions[7]
    $securePassword = $RunOptions[8]
    $credential = $RunOptions[9]
    $TrustTypeInput = $RunOptions[10]
} else {
    $assessmentType = "FULL"
    $scriptPath_base = Resolve-Path ".\SQL_Scripts\Database_Assessment"
    #$scriptPath_base = "C:\DataStrike\Database_Assessment_V8\SQL_Scripts"
}


#if we are using Windows auth of another user, we have to cap the extended query timeout to 600 otherwise things get broken
if ($authType -eq "Windows" -and $extendedQueryTimeout -gt 600){$extendedQueryTimeout = 600}

#determine how many servers we need to go through, for use in the progress updates
#This manually sets the count to one unless there are more than one lines; added due to a bug where sometimes a single server would not set the count
if ((Get-Content $servers).count -gt 1){$count = (Get-Content $servers).count}
    else {$count = 1}

#set percentage counters
$workingCount = 1
$percentInc = 100/$count
   
#Display Startup Info
if ($outputStartup -eq 1){OutputStartup $outputCSV $directoryPath $count $assessmentType $authType $username}

#Main TRY block
TRY
{   
	ForEach ($instance in Get-Content $servers){ ## Loop through each server in the text file; named instances should be entered as such: serverA\instanceName
	TRY
		{   

	        #provide progress in %  
            if($workingCount -eq 1){$percentOuter = 1} else {$percentOuter += $percentInc}
            Write-Progress -Activity Updating -Status 'Progress->' -PercentComplete $percentOuter -CurrentOperation SeverLoop
            
            #reset inner progress loop each time we start new server
            $percentInner = 0

			cd $directoryPath

           	#Create a friendly name for named instance
			$instance_friendly = $instance.replace("\", "_") 
    
			#Designate an output folder for each instance
			$outputFolder = [io.path]::Combine($outputCSV, $instance_friendly)+'\'
        
			#Create output file for each instance 
            if(Test-Path -Path $outputFolder) {get-childitem -path $outputFolder -file | remove-item}      
			if(!(Test-Path -Path $outputFolder )) {New-Item -ItemType directory -Path $outputFolder | Out-Null}

            #Get Version information
            $version = GetSQLVersion $instance
            if(!($version)){$version = $defVersion}

            #define path to scripts
            $scriptPath = "$scriptPath_base\$version"
    
			#Find Files
			$files = BuildScriptArray $scriptPath $assessmentType

            #Build MetaData
            $meta = GenerateMetaData $instance $outputFolder $version $assessmentType $scriptPath $LogPath

            ##Test Connectivity
            try{
                $t = Execute-Query -queryName $directoryPath\SQL_Scripts\999_Servername.sql -instance $instance -authtype $authtype -username $username -password $password -securepassword $securePassword -credential $credential -cmdType "cmd" -QueryTimeout $ExtendedQueryTimeout -TrustType $TrustTypeInput

                if($t.Column1 -eq $instance -or $instance -eq "localhost"){
                    Write-Host "Test Connection SUCCESSFUL"  -BackgroundColor Green -ForegroundColor White $_
                } else {
                    Write-Host "Test Connection FAILED"   -BackgroundColor Red -ForegroundColor White $_
                    
                }
                start-sleep 2
            }catch {
                Write-Host -BackgroundColor Red -ForegroundColor White $_
                Write-Host -BackgroundColor Red -ForegroundColor White "Connection test failed for $instance and will be exiting"
                
            }

			#For each file, extract content into $query
			#Set the $OutputFile to the $OutputFolder plus file name with .csv extension
			#Run each query, passing query timeout, instance name, query, and output file
			for ($i=0; $i -lt $files.Count; $i++) {

                #provide progress in %  
                $percentInner = (($i+1)/($files.Count))*100
                Write-Progress -Id 1 -Activity Updating -Status 'Progress' -PercentComplete $percentInner -CurrentOperation SQLScripts

                #output current script
				Write-Host "Executing script: " $files[$i].FullName
				$query = Get-Content $files[$i].FullName | Out-String
                $qname = $files[$i].FullName
        
				#Determine Output file for this script
				$outputFile = $outputFolder + [io.path]::GetFileNameWithoutExtension($files[$i].Name) + '.csv'
				Write-Host "Writing results to file: $outputFile"

				#look at first three characters of file name to get the script number; remove leading zero
				#this is used to check if the current query is one we marked as "slow"
				$sq = $files[$i].Name.Substring(0,3).TrimStart('0')
        
				TRY {
                        #if cancel variable is set to 1, then call slow query as a seperate process
                        #if(($sq -eq 56) -or ($sq -eq 102) -and ($cancel -eq 1)) {
                        #            start-process -filepath powershell.exe -ArgumentList "-Command &{write-host 'Running script $qname against $instance - CLOSE window to stop query early'
                        #            invoke-sqlcmd -inputfile $qname -serverinstance $instance -QueryTimeout $ExtendedQueryTimeout | export-csv $outputFile -notype
                        #            write-host 'Script $qname is complete - you can close this window'}"
                        #} ELSE {

						    
                                #set default database to master
                                if(!$database){$database = "master"}

                                
                                #For passing Other Windows Credentials
                                if ($authType -eq "Windows"){ 
                                    Execute-Query -queryName $qname -instance $instance -authtype $authtype -username $username -password $password -securepassword $securePassword -credential $credential -cmdType "cmd" -QueryTimeout $ExtendedQueryTimeout -TrustType $TrustTypeInput | export-csv $outputFile -notype  
                                }


                                #For Trusted Authentication
                                #if the timeout setting is under 10 minutes and not unlimted (0) then use the invoke-sqlcmd; otherwise call invoke-sqlcmd2
                                if (($extendedQueryTimeout -le 600 -and $extendedQueryTimeout -gt 0) -and ($authType -eq "Trusted")){ 
                                    try{
                                        #if a slow query then pass extended timeout
                                        if ($slowquery.Contains($sq)){
                                            if($TrustTypeInput -eq "T")
                                                 {
                                                    Invoke-Sqlcmd -inputfile $qName -Database $database -ServerInstance $instance -ErrorAction Stop -QueryTimeout $extendedQueryTimeout -TrustServerCertificate | export-csv $outputFile -notype
                                                 }else {
                                                    Invoke-Sqlcmd -inputfile $qName -Database $database -ServerInstance $instance -ErrorAction Stop -QueryTimeout $extendedQueryTimeout | export-csv $outputFile -notype
                                                 }
                                            
                                        } else {
                                            if($TrustTypeInput -eq "T")
                                                 {
                                                    Invoke-Sqlcmd -inputfile $qName -Database $database -ServerInstance $instance -ErrorAction Stop -QueryTimeout $QueryTimeout -TrustServerCertificate | export-csv $outputFile -notype 
                                                 }else {
                                                    Invoke-Sqlcmd -inputfile $qName -Database $database -ServerInstance $instance -ErrorAction Stop -QueryTimeout $QueryTimeout | export-csv $outputFile -notype
                                                 }                                            
                                        }
                                    }
                                    catch{
                                        Write-Host -BackgroundColor Red -ForegroundColor White $_
                                        
                                    }
                                } elseif ($authType -eq "Trusted") {
                                    try{
                                        #if a slow query then pass extended timeout; there is no option for -TrustServerCertificate in sqlcmd2, so these might fail for encrypted connections
                                        if ($slowquery.Contains($sq)){
                                            Invoke-Sqlcmd2 -inputfile $qName -Database $database -ServerInstance $instance -ErrorAction Stop -QueryTimeout $ExtendedQueryTimeout | export-csv $outputFile -notype
                                        } else {
                                            Invoke-Sqlcmd2 -inputfile $qName -Database $database -ServerInstance $instance -ErrorAction Stop -QueryTimeout $QueryTimeout | export-csv $outputFile -notype
                                        }
                                    }
                                    catch{
                                        Write-Host -BackgroundColor Red -ForegroundColor White $_
                                        
                                    }
                                }

                                
                                #For SQL Authentication
                                #if the timeout setting is under 10 minutes and not unlimted (0) then use the invoke-sqlcmd; otherwise call invoke-sqlcmd2
                                if (($extendedQueryTimeout -le 600 -and $extendedQueryTimeout -gt 0) -and ($authType -eq "SQL")){ 
                                    try{
                                        #if a slow query then pass extended timeout
                                        if ($slowquery.Contains($sq)){
                                            if($TrustTypeInput -eq "T")
                                                 {
                                                    Invoke-Sqlcmd -inputfile $qName -Database $database -ServerInstance $instance -Username $username -Password $password -ErrorAction Stop -QueryTimeout $extendedQueryTimeout -TrustServerCertificate | export-csv $outputFile -notype
                                                 }else {
                                                    Invoke-Sqlcmd -inputfile $qName -Database $database -ServerInstance $instance -Username $username -Password $password -ErrorAction Stop -QueryTimeout $extendedQueryTimeout | export-csv $outputFile -notype
                                                 }
                                            
                                        } else {
                                            if($TrustTypeInput -eq "T")
                                                 {
                                                    Invoke-Sqlcmd -inputfile $qName -Database $database -ServerInstance $instance -Username $username -Password $password -ErrorAction Stop -QueryTimeout $QueryTimeout -TrustServerCertificate | export-csv $outputFile -notype
                                                 }else {
                                                    Invoke-Sqlcmd -inputfile $qName -Database $database -ServerInstance $instance -Username $username -Password $password -ErrorAction Stop -QueryTimeout $QueryTimeout | export-csv $outputFile -notype
                                                 } 
                                        }
                                    }
                                    catch{
                                        Write-Host -BackgroundColor Red -ForegroundColor White $_
                                        
                                    }
                                } elseif ($authType -eq "SQL") {
                                    try{
                                        $credentialS = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $securepassword
                                        
                                        #if a slow query then pass extended timeout; there is no option for -TrustServerCertificate in sqlcmd2, so these might fail for encrypted connections
                                        if ($slowquery.Contains($sq)){
                                            Invoke-Sqlcmd2 -inputfile $qName -Database $database -ServerInstance $instance -Credential $credentialS -ErrorAction Stop -QueryTimeout $extendedQueryTimeout | export-csv $outputFile -notype
                                        } else {
                                            Invoke-Sqlcmd2 -inputfile $qName -Database $database -ServerInstance $instance -Credential $credentialS -ErrorAction Stop -QueryTimeout $QueryTimeout | export-csv $outputFile -notype
                                        }
                                    }
                                    catch{
                                        Write-Host -BackgroundColor Red -ForegroundColor White $_
                                        
                                    }
                                }

						     
						    
                       
                    LogScriptStatus $instance $LogPath $qname "SuccessfulScript" $meta
				}##End Try
				CATCH {
                                        
                    LogScriptStatus $instance $LogPath $qname "FailedScript" $meta

					Start-Sleep -s 3
				}##End Catch

			} #Close File Loop
    
            if($ezmode -eq 1){
            Write-Host "*****************************"
            Write-Host "HANG ON TO YOUR HATS!!!!!!!!!"
            Write-Host "*****************************"
            
            #EZDBA
            }

            LogAssessmentStatus $instance $LogPath "Success"

			#move back to the directory; added because sometimes the script would move to another folder after execution of scripts    
			cd $directoryPath

		} ##End Try
		CATCH
		{
			LogAssessmentStatus $instance $LogPath "Failed"
    
			#Cleanup blank files
			get-childItem "$outputFolder" | where {$_.length -eq 0} | Remove-Item
    
			#Cleanup empty folders
			Get-ChildItem "$outputCSV" -recurse | Where {$_.PSIsContainer -and @(Get-ChildItem -Lit $_.Fullname -r | Where {!$_.PSIsContainer}).Length -eq 0} | Remove-Item -recurse
    
		} ##End Catch

	#loop counter
	$workingCount = $workingCount + 1

	} ##Close server loop

} #Close Main TRY
CATCH
{
	Write-Host ""
	Write-Host -Fore Red "Something is broken ..."
    Write-Host -Fore Red "You will need to rerun part of the assessment"
	Write-Host ""
}

OutputSummary