#Check Signal Waits
$result = execute-query -query "Signal Waits.sql" -instance $instance -trusted $trusted -username $username -password $password -cmdType $cmdType}

#create html for table header
$html += ConvertTo-HTMLCustom -obj "Signal Waits %" -type tablehead 

#check if Signal Waits exceed 15%
if($result -ge 15){
    #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "FAILED Current Value  : $($bak)" -type tableline -bcolor red -tcolor white
    $html += ConvertTo-HTMLCustom -obj "Suggested Value: < 15%" -type tableline -color red -tcolor white
}else{
    #create html for table contents    
    $html += ConvertTo-HTMLCustom -obj "PASSED Current Value  : $($bak)" -type tableline -bcolor green -tcolor white
    $html += ConvertTo-HTMLCustom -obj "Suggested Value: < 15%" -type tableline -color green -tcolor white
}
