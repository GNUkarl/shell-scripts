#
# Karl Chavarria
# 08-05-2013
# Quick script to fix license string in FM params-sql.xml config file and restart Tomcat afterwards
#
$config = "C:\Program Files\Apache Software Foundation\Tomcat 5.5\webapps\app_name\params-sql.xml"
$backup = "C:\params-sql.xml.bak"
#
## Fixing the license string

# Verify old backup is writable and delete

If (Test-Path $backup){
	$file = Get-Item $backup
		if ($file.IsReadOnly -eq $true)  
		{  
		  $file.IsReadOnly = $false   
		}
Remove-Item $backup
}

# Copy current config to backup
Copy-Item $config $backup

# Verify config is writable
$file = Get-Item $config
if ($file.IsReadOnly -eq $true)  
{  
  $file.IsReadOnly = $false   
}

# Replace contents of ModulesLicensed w/ proper string
[xml]$myXML = Get-Content $config
$myXML.FMW.License.ModulesLicensed = "banana=="
$myXML.Save($config)

## Restarting Tomcat
Stop-Service TOMCAT5
sleep 1
Start-Service TOMCAT5