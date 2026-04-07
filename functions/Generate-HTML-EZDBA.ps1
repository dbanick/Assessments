function Generate-HTML-EZDBA ($css, $body, $html) {
#Combine all HTML elements into a single HTML report

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

return $fullhtml
}