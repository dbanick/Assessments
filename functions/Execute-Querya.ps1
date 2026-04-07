#Function to execute queries (depending on if the user will be using specific credentials or not)
function Execute-Query(
    [string]$queryName,
    [string]$instance,
    [string]$database,
    [string]$authtype,
    [string]$username,
    [string]$password,  
    [securestring]$securepassword,  
    [System.Management.Automation.PSCredential]$Credential,
    [string]$cmdType,
    [int]$QueryTimeout
){

   
    . .\functions\Invoke-SqlCmd2.ps1 #used to call queries against SQL IF the timeout is over the allowable limit for invoke-sqlcmd
    

    if(!$database){$database = "master"}
    if(!$cmdType){$cmdType = "cmd"}

    if($authtype -eq "Trusted"){
        try{ 
            if($cmdType -eq "cmd"){
                Invoke-Sqlcmd -inputfile $queryName -Database $database -ServerInstance $instance -ErrorAction Stop -QueryTimeout $QueryTimeout -TrustServerCertificate      
            }else{
                Invoke-Sqlcmd2 -inputfile $queryName -Database $database -ServerInstance $instance -ErrorAction Stop -QueryTimeout $QueryTimeout -TrustServerCertificate      
            }
        }
        catch{
            Write-Host -BackgroundColor Red -ForegroundColor White $_
            exit
        }
    }
    elseif($authtype -eq "Windows"){
        try{

          $ScriptBlock = {
                $ErrorActionPreference = 'Stop';
                return @{ Result = 
                    Invoke-Sqlcmd -inputfile $Using:queryName -Database $Using:database -ServerInstance $Using:instance -ErrorAction Stop -QueryTimeout $Using:QueryTimeout 
                    #& .\functions\Invoke-SqlCmd2.ps1 -inputfile $Using:query -Database $Using:database -ServerInstance $Using:instance -ErrorAction Stop -QueryTimeout $Using:QueryTimeout ##Not working
                    }
                } 
           
           $Job = Start-Job   -Credential $credential -ScriptBlock $ScriptBlock
           $JobResult = Wait-Job $Job;

           if ($JobResult.State -eq 'Completed') {return (Receive-Job $Job).Result}
           if ($JobResult.State -ne 'Completed') {return (Receive-Job $Job)}

        }
         catch{
            Write-Host -BackgroundColor Red -ForegroundColor White $_
            exit
        }
    }
    elseif($authtype -eq "SQL"){
        try{
            if($cmdType -eq "cmd"){
                Invoke-Sqlcmd -inputfile $queryName -Database $database -ServerInstance $instance -Username $username -Password $password -ErrorAction Stop -QueryTimeout $QueryTimeout     
            }else{
                $credentialS = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $securepassword
                Invoke-Sqlcmd2 -inputfile $queryName -Database $database -ServerInstance $instance -Credential $credentialS -ErrorAction Stop -QueryTimeout $QueryTimeout      
            }
        }
         catch{
            Write-Host -BackgroundColor Red -ForegroundColor White $_
            exit
        }
    }
}