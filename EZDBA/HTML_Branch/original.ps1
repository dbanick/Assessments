param(
   $instance = "INST201405\INST201405"
   )
#$instance =    get-content -Path "\\SSPTSQLP01A003\H$\test\instances.txt"
 $CpuCores = ((Get-WMIObject Win32_ComputerSystem).NumberOfLogicalProcessors)/(2)

if (!(Get-Module -ListAvailable -Name "SQLPS")) {
    Write-Host -BackgroundColor Red -ForegroundColor White "Module Invoke-Sqlcmd is not loaded"
    exit
}

#created function to handle HTML formatting since output is in text format and not data tables
function ConvertTo-HTMLCustom ($obj, $type, $color) {
    # add type needed to replace HTML special characters into entities
    Add-Type -AssemblyName System.Web

   if ($type -eq "tablehead"){$h = "<br><table border=1><thead><tr><th>$obj</th>"}

   if ($type -eq "tableline"){
    if ($color) {
     $h = "<tr><td style=`"background:$color; color:white;`">$obj</td></tr>"
      }
     else { 
      $h = "<tr><td>$obj</td></tr>" 
     }
    }

   if ($type -eq "tableclose"){$h = "</tr></thead><tbody><br>"}
   
    return $h.ToString()
}


#Function to execute queries (depending on if the user will be using specific credentials or not)
function Execute-Query([string]$query,[string]$database,[string]$instance,[int]$trusted,[string]$username,[string]$password){
    if($trusted -eq 1){
        try{ 
            Invoke-Sqlcmd -Query $query -Database $database -ServerInstance $instance -ErrorAction Stop -ConnectionTimeout 5 -QueryTimeout 0      
        }
        catch{
            Write-Host -BackgroundColor Red -ForegroundColor White $_
            exit
        }
    }
    else{
        try{
            Invoke-Sqlcmd -Query $query -Database $database -ServerInstance $instance -Username $username -Password $password -ErrorAction Stop -ConnectionTimeout 5 -QueryTimeout 0
        }
         catch{
            Write-Host -BackgroundColor Red -ForegroundColor White $_
            exit
        }
    }
}

function Check-CTP([string]$instance,[int]$trusted,[string]$login,[string]$password){
    $ctpQuery = "
    SELECT CONVERT(INT, ISNULL(value, value_in_use))
    FROM master.sys.configurations 
    WHERE name = 'cost threshold for parallelism'
    "

    return $(Execute-Query $ctpQuery "master" $instance $trusted $login $password)[0]
}


function Check-DOP([string]$instance,[int]$trusted,[string]$login,[string]$password){
 $CpuCores = ((Get-WMIObject Win32_ComputerSystem).NumberOfLogicalProcessors)/(2)
 
    $dopQuery = "
    SELECT CONVERT(INT, ISNULL(value, value_in_use))
    FROM master.sys.configurations 
    WHERE name = 'max degree of parallelism'
    "

    return $(Execute-Query $dopQuery "master" $instance $trusted $login $password)[0]
}


function Check-BAK([string]$instance,[int]$trusted,[string]$login,[string]$password){
    $bakQuery = "
    SELECT CONVERT(INT, ISNULL(value, value_in_use))
    FROM master.sys.configurations 
    WHERE name = 'backup compression default'
    "

    return $(Execute-Query $bakQuery "master" $instance $trusted $login $password)[0]
}

function Check-MAIL([string]$instance,[int]$trusted,[string]$login,[string]$password){
    $mailQuery = "
    SELECT CONVERT(INT, ISNULL(value, value_in_use))
    FROM master.sys.configurations 
    WHERE name = 'Database Mail XPs'
    "

    return $(Execute-Query $mailQuery "master" $instance $trusted $login $password)[0]
}
function Check-FILL([string]$instance,[int]$trusted,[string]$login,[string]$password){
    $fillQuery = "
    SELECT CONVERT(INT, ISNULL(value, value_in_use))
    FROM master.sys.configurations 
    WHERE name = 'fill factor (%)'
    "

    return $(Execute-Query $fillQuery "master" $instance $trusted $login $password)[0]
}
function Check-BOOST([string]$instance,[int]$trusted,[string]$login,[string]$password){
    $boostQuery = "
    SELECT CONVERT(INT, ISNULL(value, value_in_use))
    FROM master.sys.configurations 
    WHERE name = 'priority boost'
    "

    return $(Execute-Query $boostQuery "master" $instance $trusted $login $password)[0]
}


function Check-POOL([string]$instance,[int]$trusted,[string]$login,[string]$password){
    $poolQuery = "
    SELECT CONVERT(INT, ISNULL(value, value_in_use))
    FROM master.sys.configurations 
    WHERE name = 'lightweight pooling'
    "

    return $(Execute-Query $poolQuery "master" $instance $trusted $login $password)[0]
}

function Check-ADHOC([string]$instance,[int]$trusted,[string]$login,[string]$password){
    $adhocQuery = "
    SELECT CONVERT(INT, ISNULL(value, value_in_use))
    FROM master.sys.configurations 
    WHERE name = 'optimize for ad hoc workloads'
    "

    return $(Execute-Query $adhocQuery "master" $instance $trusted $login $password)[0]
}


function Check-DAC([string]$instance,[int]$trusted,[string]$login,[string]$password){
    $dacQuery = "
    SELECT CONVERT(INT, ISNULL(value, value_in_use))
    FROM master.sys.configurations 
    WHERE name = 'remote admin connections'
    "

    return $(Execute-Query $dacQuery "master" $instance $trusted $login $password)[0]
}


function Check-PORT([string]$instance,[int]$trusted,[string]$login,[string]$password){
    $portQuery = "
    select distinct value_data AS Port 
    from sys.dm_server_registry 
    WHERE value_name = 'TcpPort'
    "

    return $(Execute-Query $portQuery "master" $instance $trusted $login $password)[0]
}



function Check-AUDIT([string]$instance,[int]$trusted,[string]$login,[string]$password){
    $auditQuery = "
    select count(*)
FROM sys.server_audit_specification_details AS SAD
JOIN sys.server_audit_specifications AS SA
ON SAD.server_specification_id = SA.server_specification_id
JOIN sys.server_audits AS S
ON SA.audit_guid = S.audit_guid
WHERE SAD.audit_action_id IN ('CNAU', 'LGFL', 'LGSD');
    "

    return $(Execute-Query $auditQuery "master" $instance $trusted $login $password)[0]
}





function Check-LOG([string]$instance,[int]$trusted,[string]$login,[string]$password){
    $logQuery = "
    DECLARE @FileList AS TABLE (
     subdirectory NVARCHAR(4000) NOT NULL 
     ,DEPTH BIGINT NOT NULL
     ,[FILE] BIGINT NOT NULL
    );
    
    DECLARE @ErrorLog NVARCHAR(4000), @ErrorLogPath NVARCHAR(4000);
    SELECT @ErrorLog = CAST(SERVERPROPERTY(N'errorlogfilename') AS NVARCHAR(4000));
    SELECT @ErrorLogPath = SUBSTRING(@ErrorLog, 1, LEN(@ErrorLog) - CHARINDEX(N'\', REVERSE(@ErrorLog))) + N'\';
    
    INSERT INTO @FileList
    EXEC xp_dirtree @ErrorLogPath, 0, 1;
    
    DECLARE @NumberOfLogfiles INT;
    SET @NumberOfLogfiles = (SELECT COUNT(*) FROM @FileList WHERE [@FileList].subdirectory LIKE N'ERRORLOG%');
    SELECT @NumberOfLogfiles as NumberOferrorLogfiles;
	go
    "

    return $(Execute-Query $logQuery "master" $instance $trusted $login $password)[0]
}





function Check-MaxServerMemory([string]$instance,[int]$trusted,[string]$login,[string]$password){
    $maxServerMemoryQuery = "
    SELECT CONVERT(INT, ISNULL(value, value_in_use))
    FROM master.sys.configurations 
    WHERE name = 'max server memory (MB)'
    "
    $maxServerMemory = $(Execute-Query $maxServerMemoryQuery "master" $instance $trusted $login $password)[0]

    $serverMemoryQuery = "
    CREATE TABLE #MemoryValues(
    [index]         SMALLINT,
    [description]   VARCHAR(128),
    [server_memory] DECIMAL(10,2),
    [value]	        VARCHAR(64) 
    )

    INSERT INTO #MemoryValues 
    EXEC xp_msver 'PhysicalMemory'

    SELECT ROUND(CONVERT(INT,server_memory),1) FROM #MemoryValues

    DROP TABLE #MemoryValues
    "
    $serverMemory = $(Execute-Query $serverMemoryQuery "master" $instance $trusted $login $password)[0]

    if($maxServerMemory -ge (0.8 * $serverMemory) -and $maxServerMemory -le (0.85 * $serverMemory) ){return 1}

    return 0
}

function Check-LockPagesInMemory([string]$instance,[int]$trusted,[string]$login,[string]$password){
    $lockPagesInMemoryQuery = "
    SELECT CASE locked_page_allocations_kb WHEN 0 THEN 0 ELSE 1 END 
    FROM sys.dm_os_process_memory
    "
    return $(Execute-Query $lockPagesInMemoryQuery "master" $instance $trusted $login $password)[0]
}




function Check-TEMP([string]$instance,[int]$trusted,[string]$login,[string]$password){
$CpuCores1 = ((Get-WMIObject Win32_ComputerSystem).NumberOfLogicalProcessors)
    $tempQuery = "
    select count(*) FROM  tempdb.sys.database_files 
     WHERE   type = 0 ; 
    "
    return $(Execute-Query $tempQuery "master" $instance $trusted $login $password)[0]
}

function Check-InstantFileInitialization([string]$instance,[int]$trusted,[string]$login,[string]$password){
    $instantFileInitializationQuery = "
    SET NOCOUNT ON;
  
    DECLARE @show_advanced_options INT
    DECLARE @xp_cmdshell_enabled INT

    SELECT @show_advanced_options = CONVERT(INT, ISNULL(value, value_in_use))
    FROM master.sys.configurations
    WHERE name = 'show advanced options'

    IF @show_advanced_options = 0 
    BEGIN
	    EXEC sp_configure 'show advanced options', 1
	    RECONFIGURE WITH OVERRIDE 
    END 

    SELECT @xp_cmdshell_enabled = CONVERT(INT, ISNULL(value, value_in_use))
    FROM master.sys.configurations
    WHERE name = 'xp_cmdshell'

    IF @xp_cmdshell_enabled = 0 
    BEGIN
	    EXEC sp_configure 'xp_cmdshell', 1
	    RECONFIGURE WITH OVERRIDE 
    END 

    CREATE TABLE #IFI_Value(DataOut VarChar(2000))

    INSERT INTO #IFI_Value
    EXEC xp_cmdshell 'whoami /priv | findstr `"SeManageVolumePrivilege`"'

    IF @xp_cmdshell_enabled = 0 
    BEGIN
	    EXEC sp_configure 'xp_cmdshell', 0
	    RECONFIGURE WITH OVERRIDE 
    END 

    IF @show_advanced_options = 0 
    BEGIN
	    EXEC sp_configure 'show advanced options', 0
	    RECONFIGURE WITH OVERRIDE 
    END

    SELECT COUNT(1) FROM #IFI_Value WHERE DataOut LIKE '%SeManageVolumePrivilege%Enabled%'
    "
    return $(Execute-Query $instantFileInitializationQuery "master" $instance $trusted $login $password)[0]
}
function Check-DBFilesInCDrive([string]$instance,[int]$trusted,[string]$login,[string]$password){
    $dbFilesInCDriveQuery = "
    SELECT SUM(DISTINCT CASE WHEN SUBSTRING(physical_name,0,3) = 'C:' THEN 1 ELSE 0 END)
    FROM sys.master_files
    "
    return $(Execute-Query $dbFilesInCDriveQuery "master" $instance $trusted $login $password)[0]
}
function Check-DBEngineServiceAccount([string]$instance,[int]$trusted,[string]$login,[string]$password){
    $dbEngineServiceAccountQuery = "
    SELECT CASE WHEN CHARINDEX('\',service_account) > 0 AND CHARINDEX('NT Service',service_account) = 0 THEN 1 ELSE 0 END
    FROM sys.dm_server_services 
    WHERE servicename = {fn CONCAT({fn CONCAT('SQL Server (',CONVERT(VARCHAR(32),ISNULL(SERVERPROPERTY('INSTANCENAME'),'MSSQLSERVER')))},')')}
    "
    return $(Execute-Query $dbEngineServiceAccountQuery "master" $instance $trusted $login $password)[0]
}
function Check-SQLAgentServiceAccount([string]$instance,[int]$trusted,[string]$login,[string]$password){
    $sqlAgentServiceAccountQuery = "
    SELECT 
        CASE WHEN CHARINDEX('\',service_account) > 0 AND CHARINDEX('NT Service',service_account) = 0 THEN 1 ELSE 0 END,
        SUBSTRING(CONVERT(VARCHAR,SERVERPROPERTY('EDITION')),0,16)
    FROM sys.dm_server_services 
    WHERE servicename = {fn CONCAT({fn CONCAT('SQL Server Agent (',CONVERT(VARCHAR(32),ISNULL(SERVERPROPERTY('INSTANCENAME'),'MSSQLSERVER')))},')')}
    "
    if($(Execute-Query $sqlAgentServiceAccountQuery "master" $instance $trusted $login $password)[1] -eq "Express Edition"){
        return -1
    }
    return $(Execute-Query $sqlAgentServiceAccountQuery "master" $instance $trusted $login $password)[0]
}
function Check-SysAdminLogins([string]$instance,[int]$trusted,[string]$login,[string]$password){
    $sysadminLoginsQuery = "
    SELECT   name
    FROM     master.sys.server_principals 
    WHERE    IS_SRVROLEMEMBER ('sysadmin',name) = 1
    ORDER BY name
    "
    return $(Execute-Query $sysadminLoginsQuery "master" $instance $trusted $login $password)
}
function Check-DedicatedDiskDrives([string]$instance,[int]$trusted,[string]$login,[string]$password){
    $dataQuery = "
    SELECT DISTINCT SUBSTRING(physical_name,0,2) AS 'drive'
    FROM sys.master_files
    WHERE type_desc = 'ROWS'
    "
    $dataResults = Execute-Query $dataQuery "master" $instance $trusted $login $password
    
    $logQuery = "
    SELECT DISTINCT SUBSTRING(physical_name,0,2) AS 'drive'
    FROM sys.master_files
    WHERE type_desc = 'LOG'
    "
    $logResults = Execute-Query $logQuery "master" $instance $trusted $login $password
    
    $tempdbQuery = "
    SELECT DISTINCT SUBSTRING(physical_name,0,2) AS 'drive'
    FROM sys.master_files
    WHERE database_id = 2
    "
    $tempdbResults = Execute-Query $tempdbQuery "master" $instance $trusted $login $password
    
    $dataFlag  = $logFlag = $tempdbFlag = 0
    foreach($dataResult in $dataResults){
        foreach($logResult in $logResults){
            if($dataResult.drive -eq $logResult.drive){
                $dataFlag = 1
                $logFlag  = 1
            }
        }
        foreach($tempdbResult in $tempdbResults){
            if($dataResult.drive -eq $tempdbResult.drive){
                $dataFlag   = 1
                $tempdbFlag = 1
            }
        }
    }
    foreach($logResult in $logResults){        
        foreach($tempdbResult in $tempdbResults){
            if($dataResult.drive -eq $tempdbResult.drive){
                $logFlag    = 1
                $tempdbFlag = 1
            }
        }
    }
    
    return @($dataFlag,$logFlag,$tempdbFlag)
}
function Check-DatabasesGrowthPct([string]$instance,[int]$trusted,[string]$login,[string]$password){
    $databasesGrowthPctQuery = "
    SELECT name
    FROM sys.master_files
    WHERE is_percent_growth = 1
    "
    return $(Execute-Query $databasesGrowthPctQuery "master" $instance $trusted $login $password)
}

$loginChoices = [System.Management.Automation.Host.ChoiceDescription[]] @("&Trusted", "&Windows Login", "&SQL Login")
$loginChoice = $host.UI.PromptForChoice('', 'Choose login type for instance', $loginChoices, 0)
switch($loginChoice)
{
    1 { 
        $login          = Read-Host -Prompt "Enter Windows Login"
        $securePassword = Read-Host -Prompt "Enter Password" -AsSecureString
        $password       = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
      }
    2 { 
        $login          = Read-Host -Prompt "Enter SQL Login"
        $securePassword = Read-Host -Prompt "Enter Password" -AsSecureString
        $password       = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
      }
}

#Attempt to connect to the SQL Server instance using the information provided by the user
try{
    switch($loginChoice){
        0       {$buildNumber = Execute-Query "SELECT 1" "master" $instance 1 "" ""}
        default {$buildNumber = Execute-Query "SELECT 1" "master" $instance 0 $login $password}   
    }     
}
catch{
    Write-Host -BackgroundColor Red -ForegroundColor White $_
    exit
}




#clear out html var
$html = "" 

#If the connection succeeds, then proceed with the verification of best practices
Write-Host " ______   _______  _______ _________   _______  _______  _______  _______ __________________ _______  _______  _______"
Write-Host "(  ___ \ (  ____ \(  ____ \\__   __/  (  ____ )(  ____ )(  ___  )(  ____ \\__   __/\__   __/(  ____ \(  ____ \(  ____ \"
Write-Host "| (   ) )| (    \/| (    \/   ) (     | (    )|| (    )|| (   ) || (    \/   ) (      ) (   | (    \/| (    \/| (    \/"
Write-Host "| (__/ / | (__    | (_____    | |     | (____)|| (____)|| (___) || |         | |      | |   | |      | (__    | (_____ "
Write-Host "|  __ (  |  __)   (_____  )   | |     |  _____)|     __)|  ___  || |         | |      | |   | |      |  __)   (_____  )"
Write-Host "| (  \ \ | (            ) |   | |     | (      | (\ (   | (   ) || |         | |      | |   | |      | (            ) |"
Write-Host "| )___) )| (____/\/\____) |   | |     | )      | ) \ \__| )   ( || (____/\   | |   ___) (___| (____/\| (____/\/\____) |"
Write-Host "|/ \___/ (_______/\_______)   )_(     |/       |/   \__/|/     \|(_______/   )_(   \_______/(_______/(_______/\_______)"
Write-Host ""
Write-Host "##################################"
Write-Host  $instance
Write-Host "##################################"  


#Cost Threshold for Parallelism
Write-Host "##################################"
Write-Host "# Check 1 Cost Threshold for Parallelism #"
Write-Host "##################################"           
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


#Max Degree of Parallelism
Write-Host "##################################"
Write-Host "# Check 2 Max Degree of Parallelism #"
Write-Host "##################################"           
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
Write-Host "##################################"
Write-Host "# Check 3 Backup Compression #"
Write-Host "##################################"           
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
Write-Host "##################################"
Write-Host "# Check 4 Database Mail XPs #"
Write-Host "##################################"           
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
Write-Host "##################################"
Write-Host "# Check 5 fill factor (%) #"
Write-Host "##################################"           
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
Write-Host "##################################"
Write-Host "#Check 6 priority boost #"
Write-Host "##################################"           
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
Write-Host "
$html += ConvertTo-HTMLCustom -obj "" -type tableclose 


#lightweight pooling
Write-Host "##################################"
Write-Host "# Check 7 lightweight pooling #"
Write-Host "##################################"           
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
#ConvertTo-Html
# ConvertTo-Html | Out-File c:\RDX\best.html
#Stop-Transcript 

#-Path "\\SSPTSQLP01A003\H$\test\output1.txt"



$css = @"
<style>
h1, h5, th, td { text-align: center; font-family: Segoe UI; }
</style>
"@

$body  = "<h1>Best Practices Report</h1>`r`n<h2>Generated on $(Get-Date)</h5> `r`n<h2>Ran against $instance</h5>"

$fullhtml  = @"
<!DOCTYPE html>
<html>
<head>
<title>Report</title>
<meta name="generator" content="PowerShell" />
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
$css
</head>
<body>
$body
$html
</body></html>
"@


$fullhtml | out-file "C:\rdx\Report.html"