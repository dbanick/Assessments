function Invoke-SqlcmdProxy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ServerInstance,
        [Parameter(Mandatory=$true)]
        [string]$Database,
        [Parameter(Mandatory=$true)]
        [string]$InputFile,
        [Parameter()]
        [System.Data.SqlClient.PSCredential]$Credential,
        [Parameter()]
        [System.Management.Automation.PSCredential]$WindowsCredential,
        [Parameter()]
        [string]$password,  
        [Parameter()]
        [securestring]$securepassword,  
        [Parameter()]
        [int]$QueryTimeout = 30,
        [Parameter()]
        [string]$authType,
        [Parameter()]
        [string]$cmdType
    )
    try {
        if($Credential -and $WindowsCredential) {
            throw "Cannot specify both -Credential and -WindowsCredential."
        }

        . .\functions\Invoke-SqlCmd2.ps1 #used to call queries against SQL IF the timeout is over the allowable limit for invoke-sqlcmd
    

        if(!$database){$database = "master"}
        if(!$cmdType){$cmdType = "cmd"}

        if($Credential) {
            $SqlConnection = New-Object System.Data.SqlClient.SqlConnection("Server=$ServerInstance;Database=$Database;")
            $SqlConnection.Credential = $Credential
        }
        elseif($WindowsCredential) {
            $SqlConnection = New-Object System.Data.SqlClient.SqlConnection("Server=$ServerInstance;Database=$Database;")
            $SqlConnection.AccessToken = $WindowsCredential.GetNetworkCredential().Password
        }
        elseif($SqlConnection -eq $null) {
            $SqlConnection = New-Object System.Data.SqlClient.SqlConnection("Server=$ServerInstance;Database=$Database;Integrated Security=True;")
        }
        
        $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
        $SqlCmd.Connection = $SqlConnection
        $SqlCmd.CommandTimeout = $QueryTimeout

        $Script = Get-Content -Path $InputFile -Raw
        $SqlCmd.CommandText = $Script

        $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter($SqlCmd)
        $DataSet = New-Object System.Data.DataSet
        $SqlAdapter.Fill($DataSet) | Out-Null

        return $DataSet.Tables[0]
    }
    catch {
        Write-Error $_.Exception.Message
    }
    finally {
        if ($SqlConnection.State -eq 'Open') {
            $SqlConnection.Close()
        }
    }
}

