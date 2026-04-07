#Function to execute queries (depending on if the user will be using specific credentials or not)
function Execute-Query(
[string]$query,
[string]$database,
[string]$instance,
[int]$trusted,
[string]$username,
[string]$password,
[string]$cmdType,
[int]$QueryTimeout,
[string]$directoryPath
){

cd $directoryPath

. .\functions\ConvertTo-HTMLCustom.ps1
. .\functions\Generate-HTML_EZDBA.ps1

#clear out html var
$html = "" 


#Cost Threshold for Parallelism
switch($loginChoice){
    0       {$ctp = Check-CTP $instance 1 "" ""}
    default {$ctp = Check-CTP $instance 0 $login $password}   
} 
#create html for table header
$html += ConvertTo-HTMLCustom -obj "Check 1 Cost Threshold for Parallelism" -type tablehead 
if($ctp -lt 50){
    Write-Host -BackgroundColor Red -ForegroundColor White "   FAILED   Current Value  : $($ctp) "
    Write-Host -BackgroundColor Red -ForegroundColor White "            Suggested Value: >= 50   "
    
    #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "FAILED   Current Value  : $($ctp)" -type tableline -color "red"
    $html += ConvertTo-HTMLCustom -obj "Suggested Value: >= 50 " -type tableline -color "red"
    
}else{
    Write-Host -BackgroundColor Green -ForegroundColor White " PASSED  Current Value  : $($ctp) "
    Write-Host -BackgroundColor Green -ForegroundColor White "         Suggested Value: >= 50   "

    #create html for table contents 
    $html += ConvertTo-HTMLCustom -obj " PASSED  Current Value  : $($ctp)" -type tableline -color "green"
    $html += ConvertTo-HTMLCustom -obj "Suggested Value: >= 50 " -type tableline -color "green"
}
#html for table closing tags
$html += ConvertTo-HTMLCustom -obj "" -type tableclose 
Write-Host ""


<#
#Max Degree of Parallelism 
switch($loginChoice){
    0       {$dop = Check-DOP $instance 1 "" ""}
    default {$dop = Check-DOP $instance 0 $login $password}   
} 
#create html for table header
$html += ConvertTo-HTMLCustom -obj "Check 2 Max Degree of Parallelism" -type tablehead 
if($dop -ne $CpuCores){
    Write-Host -BackgroundColor Red -ForegroundColor White "  FAILED   Current Value  : $($dop)"
    Write-Host -BackgroundColor Red -ForegroundColor White "           Suggested Value: $($CpuCores)"
    
    #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "FAILED   Current Value  : $($dop)" -type tableline -color "red"
    $html += ConvertTo-HTMLCustom -obj "Suggested Value: $($CpuCores)" -type tableline -color "red"
    
}else{
    Write-Host -BackgroundColor Green -ForegroundColor White "   PASSED   Current Value  : $($dop)"
    Write-Host -BackgroundColor Green -ForegroundColor White "            Suggested Value: $($CpuCores)"
    
    #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "PASSED   Current Value  : $($dop)" -type tableline -color "green"
    $html += ConvertTo-HTMLCustom -obj "Suggested Value: $($CpuCores)" -type tableline -color "green"
    
}
$html += ConvertTo-HTMLCustom -obj "" -type tableclose 
Write-Host ""


#Compressed Backup        
switch($loginChoice){
    0       {$bak = Check-BAK $instance 1 "" ""}
    default {$bak = Check-BAK $instance 0 $login $password}   
} 
#create html for table header
$html += ConvertTo-HTMLCustom -obj "Check 3 Backup Compression" -type tablehead 
if($bak -ne 1){
    Write-Host -BackgroundColor Red -ForegroundColor White "   FAILED Current Value  : $($bak) "
    Write-Host -BackgroundColor Red -ForegroundColor White "          Suggested Value: 1  "

    #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "FAILED Current Value  : $($bak)" -type tableline -color "red"
    $html += ConvertTo-HTMLCustom -obj "Suggested Value: 1" -type tableline -color "red"
}else{
    Write-Host -BackgroundColor Green -ForegroundColor White " PASSED  Current Value  : $($bak)  "
    Write-Host -BackgroundColor Green -ForegroundColor White "         Suggested Value: 1       "

    #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "PASSED Current Value  : $($bak)" -type tableline -color green
    $html += ConvertTo-HTMLCustom -obj "Suggested Value: 1" -type tableline -color green
}
Write-Host ""
$html += ConvertTo-HTMLCustom -obj "" -type tableclose 

#DB Mail        
switch($loginChoice){
    0       {$mail = Check-MAIL $instance 1 "" ""}
    default {$mail = Check-MAIL $instance 0 $login $password}   
} 
#create html for table header
$html += ConvertTo-HTMLCustom -obj "Check 4 Database Mail XPs" -type tablehead 
if($mail -ne 1){
    Write-Host -BackgroundColor Red -ForegroundColor White "   FAILED  Current Value  : $($mail)  "
    Write-Host -BackgroundColor Red -ForegroundColor White "           Suggested Value: 1      "

    #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "FAILED  Current Value  : $($mail)" -type tableline -color "red"
    $html += ConvertTo-HTMLCustom -obj "Suggested Value: 1" -type tableline -color "red"
}else{
    Write-Host -BackgroundColor Green -ForegroundColor White "  PASSED   Current Value  : $($mail)     "
    Write-Host -BackgroundColor Green -ForegroundColor White "           Suggested Value: 1      "

    #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "PASSED  Current Value  : $($mail)" -type tableline -color "green"
    $html += ConvertTo-HTMLCustom -obj "Suggested Value: 1" -type tableline -color "green"
}
Write-Host ""
$html += ConvertTo-HTMLCustom -obj "" -type tableclose 


#fill factor (%)
switch($loginChoice){
    0       {$fill = Check-FILL $instance 1 "" ""}
    default {$fill = Check-FILL $instance 0 $login $password}   
} 
#create html for table header
$html += ConvertTo-HTMLCustom -obj "Check 5 fill factor (%)" -type tablehead 
if($fill -ne 90){
    Write-Host -BackgroundColor Red -ForegroundColor White "   FAILED   Current Value  : $($fill) .         "
    Write-Host -BackgroundColor Red -ForegroundColor White "            Suggested Value: 90      "

    #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "FAILED   Current Value  : $($fill) ." -type tableline -color "red"
    $html += ConvertTo-HTMLCustom -obj "Suggested Value: 90" -type tableline -color "red"
}else{
    Write-Host -BackgroundColor Green -ForegroundColor White " PASSED    Current Value  : $($fill) "
    Write-Host -BackgroundColor Green -ForegroundColor White "           Suggested Value: 90      "   
    
    #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "PASSED   Current Value  : $($fill) ." -type tableline -color "green"
    $html += ConvertTo-HTMLCustom -obj "Suggested Value: 90" -type tableline -color "green"          
}
Write-Host ""
$html += ConvertTo-HTMLCustom -obj "" -type tableclose 


#priority boost          
switch($loginChoice){
    0       {$boost = Check-BOOST $instance 1 "" ""}
    default {$boost = Check-BOOST $instance 0 $login $password}   
} 
#create html for table header
$html += ConvertTo-HTMLCustom -obj "Check 6 priority boost" -type tablehead 



if($boost -ne 0){
    Write-Host -BackgroundColor Red -ForegroundColor White "  FAILED   Current Value  : $($boost)          "
    Write-Host -BackgroundColor Red -ForegroundColor White "           Suggested Value: 0      "

    
    #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "FAILED   Current Value  : $($boost)" -type tableline -color "red"
    $html += ConvertTo-HTMLCustom -obj "Suggested Value: = 0 " -type tableline -color "red"

}else{
    Write-Host -BackgroundColor Green -ForegroundColor White "  PASSED  Current Value  : $($boost)          "
    Write-Host -BackgroundColor Green -ForegroundColor White "          Suggested Value: 0      "        


    #create html for table contents 
    $html += ConvertTo-HTMLCustom -obj " PASSED  Current Value  : $($boost)" -type tableline -color "green"
    $html += ConvertTo-HTMLCustom -obj "Suggested Value: = 0 " -type tableline -color "green"    
}
$html += ConvertTo-HTMLCustom -obj "" -type tableclose 


#lightweight pooling         
switch($loginChoice){
    0       {$pool = Check-POOL $instance 1 "" ""}
    default {$pool = Check-POOL $instance 0 $login $password}   
} 
#create html for table header
$html += ConvertTo-HTMLCustom -obj "Check 7 lightweight pooling" -type tablehead 
if($boost -ne 0){
    Write-Host -BackgroundColor Red -ForegroundColor White "  FAILED   Current Value  : $($pool)          "
    Write-Host -BackgroundColor Red -ForegroundColor White "           Suggested Value: 0      "


  #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "FAILED   Current Value  : $($pool) ." -type tableline -color "red"
    $html += ConvertTo-HTMLCustom -obj "Suggested Value: 0" -type tableline -color "red"

}else{
    Write-Host -BackgroundColor Green -ForegroundColor White "   PASSED   Current Value  : $($pool)   "
    Write-Host -BackgroundColor Green -ForegroundColor White "            Suggested Value: 0      "    
 #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "PASSED   Current Value  : $($pool) ." -type tableline -color "green"
    $html += ConvertTo-HTMLCustom -obj "Suggested Value: 0" -type tableline -color "green"     
      
}
Write-Host ""
$html += ConvertTo-HTMLCustom -obj "" -type tableclose 

#optimize for ad hoc workloads
Write-Host "##################################"
Write-Host "# Check 8 optimize for ad hoc workloads #"
Write-Host "##################################"           
switch($loginChoice){
    0       {$adhoc = Check-ADHOC $instance 1 "" ""}
    default {$adhoc = Check-ADHOC $instance 0 $login $password}   
} 
#create html for table header
$html += ConvertTo-HTMLCustom -obj "Check 8 optimize for ad hoc workloads" -type tablehead 
if($adhoc -ne 1){
    Write-Host -BackgroundColor Red -ForegroundColor White "  FAILED    Current Value  : $($adhoc)          "
    Write-Host -BackgroundColor Red -ForegroundColor White "            Suggested Value: 1      "

  #create html for table contents    
   $html += ConvertTo-HTMLCustom -obj "FAILED   Current Value  : $($adhoc) ." -type tableline -color "red"
    $html += ConvertTo-HTMLCustom -obj "Suggested Value: 1" -type tableline -color "red"
}else{
    Write-Host -BackgroundColor Green -ForegroundColor White "   PASSED  Current Value  : $($adhoc)   "
    Write-Host -BackgroundColor Green -ForegroundColor White "           Suggested Value: 1      "    

 #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "PASSED   Current Value  : $($adhoc) ." -type tableline -color "green"
    $html += ConvertTo-HTMLCustom -obj "Suggested Value: 1" -type tableline -color "green"           
}
Write-Host ""
$html += ConvertTo-HTMLCustom -obj "" -type tableclose 

#remote admin connections
Write-Host "##################################"
Write-Host "# Check 9 remote admin connections #"
Write-Host "##################################"           
switch($loginChoice){
    0       {$dac = Check-DAC $instance 1 "" ""}
    default {$dac = Check-DAC $instance 0 $login $password}   
} 
#create html for table header
$html += ConvertTo-HTMLCustom -obj "Check 9 remote admin connections" -type tablehead 
if($dac -ne 1){
    Write-Host -BackgroundColor Red -ForegroundColor White "  FAILED   Current Value  : $($dac)          "
    Write-Host -BackgroundColor Red -ForegroundColor White "           Suggested Value: 1      "

  #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "FAILED   Current Value  : $($dac) ." -type tableline -color "red"
    $html += ConvertTo-HTMLCustom -obj "Suggested Value: 1" -type tableline -color "red"
	

}else{
    Write-Host -BackgroundColor Green -ForegroundColor White "  PASSED  Current Value  : $($dac)      "
    Write-Host -BackgroundColor Green -ForegroundColor White "          Suggested Value: 1      "   


	 #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "PASSED   Current Value  : $($dac) ." -type tableline -color "green"
    $html += ConvertTo-HTMLCustom -obj "Suggested Value: 1" -type tableline -color "green"            
}
Write-Host ""
$html += ConvertTo-HTMLCustom -obj "" -type tableclose 


#tempdb
Write-Host "##################################"
Write-Host "# Check 10 Temp DB #"
Write-Host "##################################"           
switch($loginChoice){
    0       {$temp = Check-TEMP $instance 1 "" ""}
    default {$temp = Check-TEMP $instance 0 $login $password}   
} 
#create html for table header
$html += ConvertTo-HTMLCustom -obj "Check 10 Temp DB" -type tablehead 
if($temp -ne $CpuCores1){
   Write-Host -BackgroundColor Red -ForegroundColor White " FAILED    Current Value  : $($temp)          "
    Write-Host -BackgroundColor Red -ForegroundColor White " Suggested Value: $($CpuCores * 2) Not more than 8"

  #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "FAILED   Current Value  : $($temp) ." -type tableline -color "red"
    $html += ConvertTo-HTMLCustom -obj "Suggested Value: $($CpuCores * 2) Not more than 8" -type tableline -color "red"
    
}else{
    #Write-Host -BackgroundColor Green -ForegroundColor White "  PASSED  Current Value  : $($temp)          "
    #Write-Host -BackgroundColor Green -ForegroundColor White "  Suggested Value: $($CpuCores * 2) Not more than 8 Not more than 8"
	 #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "PASSED   Current Value  : $($temp) ." -type tableline -color "green"
    $html += ConvertTo-HTMLCustom -obj "Suggested Value: $($CpuCores * 2) Not more than 8" -type tableline -color "green"                    
}
Write-Host ""
$html += ConvertTo-HTMLCustom -obj "" -type tableclose 



#audit
#Write-Host "##################################"
#Write-Host "#SQL AUDIT #"
#Write-Host "##################################"           
#switch($loginChoice){
 #   0       {$audit = Check-AUDIT $instance 1 "" ""}
  #  default {$audit = Check-AUDIT $instance 0 $login $password}   
#} 
#if($audit -ne 3){
 #   #Write-Host -BackgroundColor Red -ForegroundColor White "      Current Value  : $($audit)          "
 #   Write-Host -BackgroundColor Red -ForegroundColor White "      Suggested Value: 3"

  #create html for table contents    
   # $html += ConvertTo-HTMLCustom -obj "FAILED   Current Value  : $($audit) ." -type tableline -color "red"
   # $html += ConvertTo-HTMLCustom -obj "Suggested Value: 3" -type tableline -color "red"
    
#}else{
   # Write-Host -BackgroundColor Green -ForegroundColor White "    PASSED    Current Value  : $($audit)          "
 #   Write-Host -BackgroundColor green -ForegroundColor White "              Suggested Value: 3"      


	 #create html for table contents    
   # $html += ConvertTo-HTMLCustom -obj "PASSED   Current Value  : $($faudit) ." -type tableline -color "green"
   # $html += ConvertTo-HTMLCustom -obj "Suggested Value: 3" -type tableline -color "green"       
#}
#Write-Host ""
#$html += ConvertTo-HTMLCustom -obj "" -type tableclose 



#errorlog files
Write-Host "##################################"
Write-Host "# Check 11 error log files #"
Write-Host "##################################"           
switch($loginChoice){
    0       {$log = Check-LOG $instance 1 "" ""}
    default {$log = Check-LOG $instance 0 $login $password}   
} 
#create html for table header
$html += ConvertTo-HTMLCustom -obj "Check 11 error log files" -type tablehead 
if($log -ne 7){
    Write-Host -BackgroundColor Red -ForegroundColor White "   FAILED   Current Value  : $($log)          "
    Write-Host -BackgroundColor Red -ForegroundColor White "            Suggested Value: 7      "
  #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "FAILED   Current Value  : $($log) ." -type tableline -color "red"
    $html += ConvertTo-HTMLCustom -obj "Suggested Value: 7" -type tableline -color "red"
	

}else{
    Write-Host -BackgroundColor Green -ForegroundColor White "   PASSED  Current Value  : $($log)          "
    Write-Host -BackgroundColor Green -ForegroundColor White "           Suggested Value: 7      "      


	
	 #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "PASSED   Current Value  : $($log) ." -type tableline -color "green"
    $html += ConvertTo-HTMLCustom -obj "Suggested Value: 7" -type tableline -color "green"         
}
Write-Host ""
$html += ConvertTo-HTMLCustom -obj "" -type tableclose 

#TCP PORT
Write-Host "##################################"
Write-Host "#Check 12 TCP PORT #"
Write-Host "##################################"           
switch($loginChoice){
    0       {$port = Check-PORT $instance 1 "" ""}
    default {$port = Check-PORT $instance 0 $login $password}   
} 
#create html for table header
$html += ConvertTo-HTMLCustom -obj "Check 12 TCP PORT" -type tablehead 
if($port -eq 1433){
    Write-Host -BackgroundColor Red -ForegroundColor White "  FAILED    Current Value  : $($PORT)          "
    Write-Host -BackgroundColor Red -ForegroundColor White "            Suggested Value: != 1433     "

  #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "FAILED   Current Value  : $($port) ." -type tableline -color "red"
    $html += ConvertTo-HTMLCustom -obj "Suggested Value: != 1433" -type tableline -color "red"

}else{
    Write-Host -BackgroundColor Green -ForegroundColor White "   PASSED            "
    Write-Host -BackgroundColor Green -ForegroundColor White "   Suggested Value: != 1433     "        


 #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "PASSED   Current Value  : $($port) ." -type tableline -color "green"
    $html += ConvertTo-HTMLCustom -obj "Suggested Value:!= 1433" -type tableline -color "green"       
}
Write-Host ""
$html += ConvertTo-HTMLCustom -obj "" -type tableclose 

#Max Server Memory
Write-Host "#####################"
Write-Host "# Check 13 Max Server Memory #"
Write-Host "#####################"          
switch($loginChoice){
    0       {$maxServerMemory = Check-MaxServerMemory $instance 1 "" ""}
    default {$maxServerMemory = Check-MaxServerMemory $instance 0 $login $password}   
} 
#create html for table header
$html += ConvertTo-HTMLCustom -obj "Check 13 Max Server Memory" -type tablehead 
if($maxServerMemory -eq 0){
    Write-Host -BackgroundColor Red -ForegroundColor White "   FAILED <80% assigned    "
  #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "FAILED   Current Value  : $($maxServerMemory) ." -type tableline -color "red"
    $html += ConvertTo-HTMLCustom -obj "Suggested Value: <80% assigned " -type tableline -color "red"

}else{
    Write-Host -BackgroundColor Green -ForegroundColor White "       PASSED   <80% assigned      "    

	 #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "PASSED   Current Value  : $($maxServerMemory) ." -type tableline -color "green"
    $html += ConvertTo-HTMLCustom -obj "Suggested Value: <80% assigned " -type tableline -color "green"          
}
Write-Host ""
$html += ConvertTo-HTMLCustom -obj "" -type tableclose 
#Lock Pages in Memory
Write-Host "########################"
Write-Host "# Check 14 Lock Pages in Memory #"
Write-Host "########################"   
switch($loginChoice){
    0       {$lockPagesInMemory = Check-LockPagesInMemory $instance 1 "" ""}
    default {$lockPagesInMemory = Check-LockPagesInMemory $instance 0 $login $password}   
} 
#create html for table header
$html += ConvertTo-HTMLCustom -obj "Check 14 Lock Pages in Memory" -type tablehead 
if($lockPagesInMemory -eq 0){
    Write-Host -BackgroundColor Red -ForegroundColor White "     FAILED  Refer  https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/enable-the-lock-pages-in-memory-option-windows?view=sql-server-ver15       "

  #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "FAILED   Current Value  : $($lockPagesInMemory) ." -type tableline -color "red"
	
    $html += ConvertTo-HTMLCustom -obj "Suggested Value:1  Refer  https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/enable-the-lock-pages-in-memory-option-windows?view=sql-server-ver15" -type tableline -color "red"
}else{
    Write-Host -BackgroundColor Green -ForegroundColor White "    PASSED    Refer  https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/enable-the-lock-pages-in-memory-option-windows?view=sql-server-ver15     "         

 #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "PASSED   Current Value  : $($lockPagesInMemory) ." -type tableline -color "green"
    $html += ConvertTo-HTMLCustom -obj "Suggested Value: 1 Refer  https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/enable-the-lock-pages-in-memory-option-windows?view=sql-server-ver15" -type tableline -color "green"     

}
Write-Host ""
$html += ConvertTo-HTMLCustom -obj "" -type tableclose 

#Instant File Initialization
Write-Host "###############################"
Write-Host "# Check 15 Instant File Initialization #"
Write-Host "###############################" 
switch($loginChoice){
    0       {$instantFileInitialization = Check-InstantFileInitialization $instance 1 "" ""}
    default {$instantFileInitialization = Check-InstantFileInitialization $instance 0 $login $password}   
} 
#create html for table header
$html += ConvertTo-HTMLCustom -obj "Check 15 Instant File Initialization" -type tablehead 
if($instantFileInitialization -eq 0){
    Write-Host -BackgroundColor Red -ForegroundColor White "      FAILED  refer https://docs.microsoft.com/en-us/sql/relational-databases/databases/database-instant-file-initialization?view=sql-server-ver15           "
  #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "FAILED   Current Value  : $($instantFileInitialization) ." -type tableline -color "red"
	$html += ConvertTo-HTMLCustom -obj "Suggested Value:1  refer https://docs.microsoft.com/en-us/sql/relational-databases/databases/database-instant-file-initialization?view=sql-server-ver15" -type tableline -color "red"

}else{


    Write-Host -BackgroundColor Green -ForegroundColor White "     PASSED    refer https://docs.microsoft.com/en-us/sql/relational-databases/databases/database-instant-file-initialization?view=sql-server-ver15   "    
	 #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "PASSED   Current Value  : $($instantFileInitialization) ." -type tableline -color "green"
	
    $html += ConvertTo-HTMLCustom -obj "Suggested Value: 1 refer https://docs.microsoft.com/en-us/sql/relational-databases/databases/database-instant-file-initialization?view=sql-server-ver15" -type tableline -color "green"     

}
Write-Host ""
$html += ConvertTo-HTMLCustom -obj "" -type tableclose 

#DB Files in C:\ drive
Write-Host "#########################"
Write-Host "# Check 16 DB Files in C:\ drive #"
Write-Host "#########################"
switch($loginChoice){
    0       {$dbFilesInCDrive = Check-DBFilesInCDrive $instance 1 "" ""}
    default {$dbFilesInCDrive = Check-DBFilesInCDrive $instance 0 $login $password}   
} 
#create html for table header
$html += ConvertTo-HTMLCustom -obj "Check 16 DB Files in C:\ drive" -type tablehead 
if($dbFilesInCDrive -eq 1){
    Write-Host -BackgroundColor Red -ForegroundColor White "         FAILED    Avoid DB related files in C:      "
    #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "FAILED    Avoid DB related files in C:" -type tableline -color "green"
}else{
    Write-Host -BackgroundColor Green -ForegroundColor White "       PASSED      Avoid DB related files in C:     "
    #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "PASSED    Avoid DB related files in C:" -type tableline -color "green"
}
Write-Host ""
$html += ConvertTo-HTMLCustom -obj "" -type tableclose 

#DB Engine Service Account
Write-Host "#############################"
Write-Host "# Check 17 DB Engine Service Account #"
Write-Host "#############################"
switch($loginChoice){
    0       {$dbEngineServiceAccount = Check-DBEngineServiceAccount $instance 1 "" ""}
    default {$dbEngineServiceAccount = Check-DBEngineServiceAccount $instance 0 $login $password}   
} 
#create html for table header
$html += ConvertTo-HTMLCustom -obj "Check 17 DB Engine Service Account" -type tablehead 
if($dbEngineServiceAccount -eq 0){
    Write-Host -BackgroundColor Red -ForegroundColor White "         FAILED      It should be a domain account      "
    #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "FAILED     It should be a domain account" -type tableline -color "green"
}else{
    Write-Host -BackgroundColor Green -ForegroundColor White "       PASSED     It should be a domain account       "
    #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "PASSED     It should be a domain account" -type tableline -color "green"
}
Write-Host ""
$html += ConvertTo-HTMLCustom -obj "" -type tableclose 

#SQL Agent Service Account
Write-Host "#############################"
Write-Host "# Check 18 SQL Agent Service Account #"
Write-Host "#############################"
switch($loginChoice){
    0       {$sqlAgentServiceAccount = Check-SQLAgentServiceAccount $instance 1 "" ""}
    default {$sqlAgentServiceAccount = Check-SQLAgentServiceAccount $instance 0 $login $password}   
} 
#create html for table header
$html += ConvertTo-HTMLCustom -obj "Check 18 SQL Agent Service Account" -type tablehead 
if($sqlAgentServiceAccount -eq -1){
    Write-Host -BackgroundColor Green -ForegroundColor White "    Using Express Edition    "
    #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "Using Express Edition" -type tableline -color "green"
}

if($sqlAgentServiceAccount -eq 0){
    Write-Host -BackgroundColor Red -ForegroundColor White "           FAILED            "
        #create html for table contents    
        $html += ConvertTo-HTMLCustom -obj "FAILED" -type tableline -color "red"
}else{
    Write-Host -BackgroundColor Green -ForegroundColor White "         PASSED            "
        #create html for table contents    
        $html += ConvertTo-HTMLCustom -obj "PASSED" -type tableline -color "green"
}
Write-Host ""
$html += ConvertTo-HTMLCustom -obj "" -type tableclose 

#Logins with sysadmin privilege
Write-Host "##################################"
Write-Host "# Check 19 Logins with sysadmin privilege #"
Write-Host "##################################"
switch($loginChoice){
    0       {$sysadminLogins = Check-SysadminLogins $instance 1 "" ""}
    default {$sysadminLogins = Check-SysadminLogins $instance 0 $login $password}   
} 
#create html for table header
$html += ConvertTo-HTMLCustom -obj "Check 19 Logins with sysadmin privilege" -type tablehead 
foreach($sysadminLogin in $sysadminLogins){
    if($sysadminLogin.name -eq 'sa' -or $sysadminLogin.name -like '*NT SERVICE*'){
        Write-Host -BackgroundColor Green -ForegroundColor White $sysadminLogin.name

        #create html for table contents    
        $html += ConvertTo-HTMLCustom -obj $sysadminLogin.name -type tableline -color "green"
    }else{
        Write-Host -BackgroundColor Red -ForegroundColor White $sysadminLogin.name

        #create html for table contents    
        $html += ConvertTo-HTMLCustom -obj $sysadminLogin.name -type tableline -color "red"
    }
}
Write-Host ""
$html += ConvertTo-HTMLCustom -obj "" -type tableclose 

#Dedicated Disk Drives
Write-Host "#########################"
Write-Host "# Check 20 Dedicated Disk Drives #"
Write-Host "#########################"
switch($loginChoice){
    0       {$dedicatedDiskDrives = Check-DedicatedDiskDrives $instance 1 "" ""}
    default {$dedicatedDiskDrives = Check-DedicatedDiskDrives $instance 0 $login $password}   
} 
#create html for table header
$html += ConvertTo-HTMLCustom -obj "Check 20 Dedicated Disk Drives" -type tablehead 
switch($dedicatedDiskDrives[0]){
    0{Write-Host -BackgroundColor Green -ForegroundColor White "      Data: PASSED       "
        #create html for table contents    
        $html += ConvertTo-HTMLCustom -obj "Data: PASSED" -type tableline -color "green"}
    1{Write-Host -BackgroundColor Red -ForegroundColor White "      Data: FAILED       "
        #create html for table contents    
        $html += ConvertTo-HTMLCustom -obj "Data: FAILED" -type tableline -color "red"}
}
switch($dedicatedDiskDrives[1]){
    0{Write-Host -BackgroundColor Green -ForegroundColor White "       Log: PASSED       "
        #create html for table contents    
        $html += ConvertTo-HTMLCustom -obj "Log: PASSED" -type tableline -color "green"}
    1{Write-Host -BackgroundColor Red -ForegroundColor White "       Log: FAILED       "
        #create html for table contents    
        $html += ConvertTo-HTMLCustom -obj "Log: FAILED" -type tableline -color "red"}
}
switch($dedicatedDiskDrives[2]){
    0{Write-Host -BackgroundColor Green -ForegroundColor White "    TempDB: PASSED       "
        #create html for table contents    
        $html += ConvertTo-HTMLCustom -obj "TempDB: PASSED" -type tableline -color "green"}
    1{Write-Host -BackgroundColor Red -ForegroundColor White "    TempDB: FAILED       "
         #create html for table contents    
        $html += ConvertTo-HTMLCustom -obj "TempDB: FAILED" -type tableline -color "red"}
}
Write-Host ""
$html += ConvertTo-HTMLCustom -obj "" -type tableclose 

#Databases with growth in %
Write-Host "###################################"
Write-Host "# Check 21 Database files with growth in % #"
Write-Host "###################################"           
switch($loginChoice){
    0       {$databasesGrowthPct = Check-DatabasesGrowthPct $instance 1 "" ""}
    default {$databasesGrowthPct = Check-DatabasesGrowthPct $instance 0 $login $password}   
} 
#create html for table header
$html += ConvertTo-HTMLCustom -obj "Check 21 Database files with growth in %" -type tablehead 
if($databasesGrowthPct.length -eq 0){
    Write-Host -BackgroundColor Green -ForegroundColor White "              PASSED               "
    
    #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj $db.name -type tableline -color "green"
}else{
    foreach($db in $databasesGrowthPct){
        Write-Host -BackgroundColor Red -ForegroundColor White $db.name  

        #create html for table contents    
        $html += ConvertTo-HTMLCustom -obj $db.name -type tableline -color "red"
           
    }
}
Write-Host "" 
$html += ConvertTo-HTMLCustom -obj "" -type tableclose 
#>

$rpt = Generate-HTML_EZDBA

return $rpt

}