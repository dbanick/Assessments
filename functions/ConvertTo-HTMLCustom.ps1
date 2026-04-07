function ConvertTo-HTMLTables ($obj, $type, $bcolor, $tcolor) {
    # add type needed to replace HTML special characters into entities
    Add-Type -AssemblyName System.Web

    #Build Table Header tags
   if ($type -eq "tablehead"){$h = "<br><table border=1><thead><tr><th>$obj</th>"}

   #Build tags for each table row
   if ($type -eq "tableline"){
    if ($color) {
     $h = "<tr><td style=`"background:$bcolor; color:$tcolor;`">$obj</td></tr>"
      }
     else { 
      $h = "<tr><td>$obj</td></tr>" 
     }
    }

    #Close Table Tags
   if ($type -eq "tableclose"){$h = "</tr></thead><tbody><br>"}
   
    return $h.ToString()
}
