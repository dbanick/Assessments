#Check Database Corruption
$result = execute-query -query "Corruption.sql" -instance $instance -trusted $trusted -username $username -password $password -cmdType $cmdType}

#create html for table header
$html += ConvertTo-HTMLCustom -obj "Is Database Corruption Detected" -type tablehead 

#check if corruption is present
if($result -ne "No Corruption"){
    #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "FAILED Current Value  : $($bak)" -type tableline -bcolor red -tcolor white
    $html += ConvertTo-HTMLCustom -obj "INVESTIGATION REQUIRED" -type tableline -color red -tcolor white
}else{
    #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "PASSED Current Value  : $($bak)" -type tableline -bcolor green -tcolor white
    $html += ConvertTo-HTMLCustom -obj "No Database Corruption" -type tableline -color green -tcolor white
}
