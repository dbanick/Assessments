function GetSQLVersion {

<#
        .SYNOPSIS
            Runs a T-SQL script.

        .DESCRIPTION
            Runs a T-SQL script to determine the version of SQL and generates variables based on the output


        .PARAMETER ServerInstance
            Specifies the SQL Server instance(s) to execute the query against.


        .INPUTS
            String[]
                You can only pipe strings to GetSQLVersion: they will be considered as passed -ServerInstance(s)

        .OUTPUTS
        As PSObject:     System.Management.Automation.PSCustomObject
        As DataRow:      System.Data.DataRow
        As DataTable:    System.Data.DataTable
        As DataSet:      System.Data.DataTableCollectionSystem.Data.DataSet
        As SingleValue:  Dependent on data type in first column.

        .EXAMPLE
            GetSQLVersion -ServerInstance "MyComputer\MyInstance" 

            Connects to a named instance of the Database Engine on a computer and determines the version of SQL.

#>
    param(
        [Parameter(Position = 0,
        Mandatory = $true,
        ValueFromPipelineByPropertyName = $true,
        ValueFromRemainingArguments = $false)]
        [string[]]$ServerInstance
    )


	[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null

	#determine version of current instance in loop
	$s = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $ServerInstance
	$v = $s | select version

	if ($v.version -like '8.*') {$version = "2000"
		Write-Host -Fore Red “Running LIMITED scripts for SQL 2000"}

	if ($v.version -like '9.*') {$version = "2005"
		Write-Host -Fore Green “Running SQL 2005 scripts"}
	if ($v.version -like '10.0*') {$version = "2008"
		Write-Host -Fore Green “Running SQL 2008 scripts"}
	if ($v.version -like '10.5*') {$version = "2008R2"
		Write-Host -Fore Green “Running SQL 2008R2 scripts"}
	if ($v.version -like '11*') {$version = "2012"
		Write-Host -Fore Green “Running SQL 2012 scripts"}
	if ($v.version -like '12*') {$version = "2014"
		Write-Host -Fore Green “Running SQL 2014 scripts"} 
	if ($v.version -like '13*') {$version = "2016"
		Write-Host -Fore Green “Running SQL 2016 scripts"}
	if ($v.version -like '14*') {$version = "2017"
		Write-Host -Fore Green “Running SQL 2017 scripts"} 
	if ($v.version -like '15*') {$version = "2019"
		Write-Host -Fore Green "Running SQL 2019 scripts"}
	if ($v.version -like '16*') {$version = "2022"
		Write-Host -Fore Green "Running SQL 2022 scripts"} 

	if ($v.version -like '17*') {$version = "2022"
		Write-Host -Fore Red "This is not supported for versions newer than 2022 but attempting anyways"} 			
	if ($v.version -like '18*') {$version = "2022"
		Write-Host -Fore Red "This is not supported for versions newer than 2022 but attempting anyways"} 


    if ($version -eq $null) {Write-Host -Fore Red "Unable to connect to $ServerInstance to determine version"} 

	return $version
}