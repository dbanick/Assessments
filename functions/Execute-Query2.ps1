#Function to execute queries (depending on if the user will be using specific credentials or not)
function Execute-Query2(
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



    if(!$database){$database = "master"}
    if(!$cmdType){$cmdType = "cmd"}

    if($authtype -eq "Windows"){
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
    
}