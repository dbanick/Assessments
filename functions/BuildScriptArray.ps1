function BuildScriptArray {
    param($scriptPath, $assessmentType)

    #determine full list of potential scripts
    $files = Get-ChildItem $scriptPath

    $array = @()

    #Find Files
    #Most cases will be FULL assessments, so set this as first thing to check
    #Security and SASAT are also scanning their entire directories, so no config file for these
    #IF ($assessmentType -eq "SECURITY") {$array += Get-ChildItem $scriptPath}
    IF ($assessmentType -eq "CYBER_HYGIENE") {$array += Get-ChildItem $scriptPath}
    IF ($assessmentType -eq "FULL") {$array += Get-ChildItem $scriptPath}

    #IF ($assessmentType -ne "SECURITY" -and $assessmentType -ne "CYBER_HYGIENE" -and $assessmentType -ne "FULL")  {
	IF ($assessmentType -ne "CYBER_HYGIENE" -and $assessmentType -ne "FULL")  {
    write-host "DOING ELSE STUFF"
        #determine which scripts to grab based on assessment type
        if ($assessmentType -eq "PERF") {$configs = ".\configs\PERF.txt"}
		if ($assessmentType -eq "SECURITY") {$configs = ".\configs\SECURITY.txt"}
        if ($assessmentType -eq "CONFIG") {$configs = ".\configs\CONFIG.txt"}
        if ($assessmentType -eq "MINI") {$configs = ".\configs\MINI.txt"}
	    if ($assessmentType -eq "RDS") {$configs = ".\configs\RDS.txt"}
        if ($assessmentType -eq "CUSTOM") {$configs = ".\configs\CUSTOM.txt"}

    
        $configItems = get-content $configs
    
        #loop through and find scripts that match the assessment type
        for ($configIndex = 0; $configIndex -lt $configItems.Length; $configIndex++) {
            for ($fileIndex = 0; $fileIndex -lt $files.Length; $fileIndex++) {
                if ($files[$fileIndex].Name.Substring(0,3) -match $configItems[$configIndex]) { 
                    $array += ,$files[$fileIndex]}
            }
        }
            
    }

    return $array 
}