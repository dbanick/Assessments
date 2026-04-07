######################################
# Assessment Powershell Script        #
############################################
# Created 03/15/2017                       #
# By: Nick Patti                           #
#######################################################################
# This Powershell script compiles all the CSV files in the CSV folder #
# And creates a spreadsheet for each instance                         #
#######################################################################
############################## Features to Add ##############################################################################################
# Parameterize the script, to determine type of assessment, and pass in the appropriate templates/scripts as needed.        #
#############################################################################################################################################
############################## Change Control ##########################################
# Version 2.0                                                                          #
# Date:  9/6/17                                                                        #
# Modified By:   Nick Patti                                                            #
# Change Log:                                                                          #
#  1. Changed the file name convention to "rdx-sql-server-full-assesment-diagnostics-" #
#                                                                                      #
# Version 3.0                                                                          #
# Date:  04/2020                                                                       #
# Modified By:   Nick Patti                                                            #
# Change Log:                                                                          #
#  1. Added option to use Excel table formatting                                       #
#  2. Added Hyperlinks back to Table of Contents;                                      #
#     auto sized column A based on the Header width                                    #
#                                                                                      #
# Version 4.0                                                                          #
# Date: 06/2020                                                                        #
# Modified By:   Nick Patti                                                            #
# Change Log:                                                                          #
#  1. Created functions for various tasks to make script more modular                  #
#                                                                                      #
#Version 5.0                                                                           #
#Date 09/2020                                                                          #
#Modified By: Nick Patti                                                               #
#  1. Provided options for different assessment types			                       #
#  2. Input variables are now more user friendly				                       #
#  3. Added progress bar							                                   #
#                                                                                      #
#Version 6.0                                                                           #
#Date 11/2020                                                                          #
#Modified By: Nick Patti                                                               #
#  1. Minor bug fixes							                                       #
#                                                                                      #
#Version 7.0                                                                           #
#Date 02/2023                                                                          #
#Modified By: Nick Patti                                                               #
#  1. Added options for RDS assessments					                               #
#  2. Minor Bug Fixes								                                   #
#  3. Laid groundwork for EZDBA scripts (WIP)					                       #
#  4. Added support for SQL 2022						                               #
#                                                                                      #
#Version 8.0                                                                           #
#Date 01/2024                                                                          #
#Modified By: Nick Patti                                                               #
#  1. bug fixes for RDS assessments					                                   #
#                                                                                      #
#Version 9.0                                                                           #
#Date 02/2025                                                                          #
#Modified By: Nick Patti                                                               #
#  1. Formatting changes, font color, table color, logo, templates                     #
#  2. Fixed relational pathing                                                         #
#  3. Added "$Debugger" option to avoid CSV files from being moved out for testing     #
########################################################################################

cls

#determine the assessment folder based of where this is executed from; you can also explicitly define it here
$directoryPath = Split-Path $MyInvocation.MyCommand.Path
cd $directoryPath

########DEFAULT VARIALBES#################
#These will be based off the current run directory but you can hardcode it as well
$prompt = 0 #0 = Do not prompt for input variables; #1 = prompt for input variables
$TOCorig = "$directoryPath\templates\" #define template spreadsheet to pull Table of Contents from
$imgPath = "$directoryPath\templates\Logo.png" #define path for image file (DataStrike logo)
$outputName = 'DataStrike_SQL_Assesment_'
$dt = Get-Date -format "MM_dd_yyyy"
$tables = 1 #Set to 1 if you want excel tables in each worksheet
#########################################

############determine some initial variables based on where we are########################
$outputCSV = "CSV"
$compiledCSV = "Compiled_Spreadsheets"
$processedCSV = "Processed_CSV"
$LogPath = "logs"
$pct = 0
$debugger = 0 #setting this to 1 will prevent the CSV files from being moved out so you can rerun this easier for testing; not recommended for multiple servers

#define some parameters for inserting new rows
$xldown = -4121 # see: http://msdn.microsoft.com/en-us/library/bb241212(v=office.12).aspx
$xlup = -4162
#define some parameters for the logo placement #https://docs.microsoft.com/en-us/office/vba/api/excel.shapes.addpicture
$Left = 0
$Top = 0
$Width = -1 #275
$Height = -1 #78
#define the color scheme of the headers; this uses the RGB values you can find in Excel when choosing custom colors
$blue = 0
$green= 0
$red = 0
$color = [long] ($red + ($green * 256) + ($blue * 65536))
#$color = [long] ($blue + ($green * 256) + ($red * 65536)) #troubleshooting font color mixup in v8 - JC
###########################################################################################



#######Qualify the function used#############
. .\functions\ConvertCSV-ToExcel.ps1 #this function will automatically remove the 4 characters of the file name (e.g. 001_) and use that to define the sheetname
. .\functions\ConvertCSV-ToExcel_Tables.ps1 #same as previous, but use Table Formatting
. .\functions\OutputCompileStartup.ps1 #display startup details
. .\functions\OutputCompileSummary.ps1 #display completion details
. .\functions\LogCompileStatus.ps1 #log results to file
. .\functions\FormatSheets.ps1 #format each sheet in excel
. .\functions\SetCompileOptions.ps1 #set default values and then allow overwrides through input
. .\functions\DownloadBuilds.ps1 #download list of all SQL builds
#############################################

#DownloadBuilds -outputFile $buildFile

#######CHECK FOLDERS####################
    #Create compiled output folder if not exists
    if(!(Test-Path -Path $compiledCSV )) {New-Item -ItemType directory -Path $compiledCSV | Out-Null}
    #Create processed folder for completed servers if not exists
    if(!(Test-Path -Path $processedCSV )) {New-Item -ItemType directory -Path $processedCSV | Out-Null}
    #Create log folder if not exists
    if(!(Test-Path -Path $LogPath )) {New-Item -ItemType directory -Path $LogPath | Out-Null}
    
    $outputCSV = Resolve-Path "CSV"    
    $compiledCSV = Resolve-Path "Compiled_Spreadsheets"
    $processedCSV = Resolve-Path "Processed_CSV"
    $LogPath = Resolve-Path "logs"
    
    #Find Folders to process
    $files = Get-ChildItem $outputCSV 
    #Verify they are actually folders
    $folders = $files | where-object { $_.PSIsContainer }
    
    #Let's see how many folders we are dealing with
    If (!$folders.Count) {$count=0}
    Else {$count = $folders.Count}  
#####################################

#######Get Compile Options###########
if($prompt -eq 1){
$CompileOptions = SetCompileOptions $tables $outputName $outputCSV
$tables = $CompileOptions[1]
$outputName = $CompileOptions[2]
} 
#####################################

cd $directoryPath

#Begin main TRY block for processing all the CSV files
TRY
{          
    #display startup info
    OutputCompileStartup $compiledCSV $processedCSV $LogPath $count
    
    #set percentage counters
    $percentOuter = 0
    $percentInc = 100/$count

    #For each folder
    foreach ($folder in $folders) {

		#Move to the directory we will process to make life easier      
		$workingFolder = $folder.FullName
		$workingFolderFriendly = $folder.Name
		Write-Host "Processing CSV files in $workingFolder"
		cd $workingFolder

		#Begin TRY block for processing each folder
		TRY
		{
            #update progress variable
            if($folder -eq $folders[0]){$percentOuter = 1}
            else {$percentOuter += $percentInc}

            #provide progress in %  
            Write-Progress -Activity Updating -Status 'Progress->' -PercentComplete $percentOuter -CurrentOperation SeverLoop
            
            #find non-meta files
            $FileList = Get-ChildItem *.csv | Where-Object { !$PsIsContainer -and [System.IO.Path]::GetFileNameWithoutExtension($_.Name) -notmatch "META"}

            #find meta file
            $meta = gci | Where-Object { !$PsIsContainer -and [System.IO.Path]::GetFileNameWithoutExtension($_.Name) -match "META" -and [System.IO.Path]::GetFileNameWithoutExtension($_.Name) -notmatch "retry"}
            $metaName = $meta.FullName
    
            #split meta data
            $contents = import-csv $metaName
            $instance = $contents | ? datatype -like *version* | select-object servername #get instance name
            $instance = $instance.servername
            $version = $contents | ? datatype -like *version* | select-object value #get version
            $version = $version.value
            $assessmentType = $contents | ? datatype -like *AssessmentType* | select-object value #get assessment type
            $assessmentType = $assessmentType.value

			#Build the output file name
			$report = "$outputName`_$assessmentType`_$workingFolderFriendly`_$dt.xlsx" 

            #find correct assessment template/ Table of Contents
            $TOC = $TOCorig #set template back to default directory and then figure out again since this may be different per assessment
            if ($assessmentType -eq "FULL") {$TOC = "$TOC\Full Assessment Gathering Template.xlsm"}
            if ($assessmentType -eq "MINI") {$TOC = "$TOC\Mini Assessment Gathering Template.xlsm"}
            if ($assessmentType -eq "PERF") {$TOC = "$TOC\Performance Assessment Gathering Template.xlsm"}
            if ($assessmentType -eq "CONFIG") {$TOC = "$TOC\Configuration Assessment Gathering Template.xlsm"}
            if ($assessmentType -eq "CUSTOM") {$TOC = "$TOC\Full Assessment Gathering Template.xlsm"}
            if ($assessmentType -eq "SECURITY") {$TOC = "$TOC\SECURITY Assessment Gathering Template.xlsm"}
            if ($assessmentType -eq "CYBER_HYGIENE") {$TOC = "$TOC\CYBER_HYGIENE Assessment Gathering Template.xlsm"}
	        if ($assessmentType -eq "RDS") {$TOC = "$TOC\RDS Assessment Gathering Template.xlsm"}

            #output findings from Meta
            Write-Host "Working on instance $instance which is version $version and has a $assessmentType assessment detected"
       
			#Run the convert function against all CSV files in the current folder, generating the output file in same folder (for now)
			#Each sheet will be named the same as the CSV file name, removing the first 4 characters. We assume the csv is named XXX_<desired name>
			if ($tables -eq 0){
                Get-ChildItem *.csv | Where-Object { !$PsIsContainer -and [System.IO.Path]::GetFileNameWithoutExtension($_.Name) -notmatch "META"} |  Sort -desc | ConvertCSV-ToExcel -output $report -filecount $fileList.count
            } else {
                Get-ChildItem *.csv | Where-Object { !$PsIsContainer -and [System.IO.Path]::GetFileNameWithoutExtension($_.Name) -notmatch "META"} |  Sort -desc | ConvertCSV-ToExcel_Tables -output $report -filecount $fileList.count
            }
            
			#If it succeeds, move the output file to the compiled folder, overwriting any existing entries
			Move-Item .\$report $compiledCSV -force | Out-Null
			Write-Host -Fore Green "File saved to $compiledCSV\$report"
        
			#Move out of the current directory so we can copy the processed folder to our desired location
			cd $processedCSV
            if(test-path($workingFolderFriendly)){remove-item $workingFolderFriendly -force} #remove processed folder if it already exists
			if($debugger -ne 1){Move-Item $workingFolder $processedCSV -force  | Out-Null } #move folder from working dir to processed dir unless $debugger is enabled
			Write-Host -Fore Green "Compilation completed - moving $workingFolder to $processedCSV"

			#now that the file is compiled, let's format it
			#connect to excel; open file
			$ExcelPath = "$compiledCSV\$report"
			$Excel = New-Object -ComObject Excel.Application
			$Excel.Visible = $false #do the work without opening the file on user's desktop
			$ExcelWordBook = $Excel.Workbooks.Open($ExcelPath)

			#for each sheet run formatting scripts
			for ($ic=1; $ic -le $ExcelWordBook.sheets.count; $ic++){
				$sh=$ExcelWordBook.Sheets.Item($ic)
                FormatSheets $sh $xldown $color
			}

			#now we will pull the Table of Contents from a template file into the current workbook
			$ExcelWordBook2 = $Excel.workbooks.open($TOC, $null, $true) # open source, readonly 
			$sh1_wb1 = $ExcelWordBook.sheets.item(1) # first sheet in destination workbook 
			$sheetToCopy = $ExcelWordBook2.sheets.item('Table of Contents') # source sheet to copy 
			$sheetToCopy.copy($sh1_wb1) # copy source sheet to destination workbook 
			$ExcelWordBook2.close($false) # close source workbook w/o saving 

			#close up shop; save/quit excel
			$ExcelWordBook.save()
			$Excel.Quit()
        
            LogCompileStatus $workingFolderFriendly $LogPath "Success"

		}#End catch block for trying each folder
		CATCH
		{
            LogCompileStatus $workingFolderFriendly $LogPath "Failed"

		}#End catch block for trying each folder



    } #Close Folder Loop
} 
CATCH
{
	Write-Host ""
	Write-Host -Fore Red "Something is broken ..."
	Start-Sleep -s 1
} ##End main TRY/CATCH

OutputCompileSummary

