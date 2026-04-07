function FormatSheets{
	param($sh, $xldown, $color)

				#Determine name for the header
				$headerName = $sh.Name

                #output raw sheet name
				write-host "Formatting Sheet: $headerName"

				#select entire row in A1 (1,1)
				$eRow = $sh.cells.item(1,1).entireRow
				#$eRow
    
				#insert two blank rows in A1
				$active = $eRow.insert($xldown)
				$active = $eRow.insert($xldown)
        
				#in A2 (2,1), insert the header name
				$sh.cells.item(2,1) = "$headerName"

				#format the header name
				$format = $sh.cells.item(2,1)
				$format.Font.Color = $color     
				$format.Font.Bold = "True"
				$format.Font.Size = 20
				$format.RowHeight = 30.5
                $format.EntireColumn.Autofit() | out-null

				#format the A1 (1,1) cell where the image will be placed
				$formatLogo = $sh.cells.item(1,1)
				$formatLogo.RowHeight = 65.5

				# add image to the Sheet
				$img = $sh.Shapes.AddPicture($imgPath, 0, 1, $Left, $Top, $Width, $Height)

                #add hyperlink in B2 (2,2) pointing to 'Table of Contents'!A1
                $sh.Hyperlinks.Add(
                $sh.cells.item(2,2), #where to place hyperlink
                "", #Subaddress
                "`'Table of Contents`'!A1", #Link
                "Back to Table of Contents", #Mouseover Text
                "Back to Table of Contents" #Text in Cell
                ) | Out-Null

}