param($installPath, $toolsPath, $package, $project)

if(!$projectPath) {
	$projectPath = Split-Path $project.FullName
}

Function AddFileToProjectIfItIsMissing([string] $filename,[string] $source) {
	$targetPath = Join-Path $projectPath $filename
	Write-host "Checking $targetPath"
	if(!(Test-Path $targetPath)) {
		Write-Host "Adding missing file $filename to project"
		Write-Host "Copy $source to $targetPath"
		copy $source $targetPath
		$project.ProjectItems.AddFromFile($targetPath)|out-null
	}
}

if($project){
    AddFileToProjectIfItIsMissing "imagevault.client.config" (join-path $toolsPath "imagevault.client.config")
}


#[regex]$regex = "\bPublicKeyToken\s*=\s*(?<publicKeyToken>\w+)"

#Marks the file as to be copied to the output directory if it is newer
Function SetCopyToOutputDirectory([string] $filename) {
	$file = $project.ProjectItems.Item($filename)

	# set 'Copy To Output Directory' to 'Copy if newer'
	$copyToOutput = $file.Properties.Item("CopyToOutputDirectory")
	$copyToOutput.Value = 2
}

#Updates the supplied assemblyConfigs for the supplied file
Function UpdateBindingRedirect([System.IO.FileInfo] $file, [System.Xml.XmlElement] $assemblyBinding, [System.Xml.XmlElement[]] $assemblyConfigs) {
	$name = [System.IO.Path]::GetFileNameWithoutExtension($file)
	$assemblyName = [System.Reflection.AssemblyName]::GetAssemblyName($file)
	$publicKeyTokenArray = [System.Reflection.AssemblyName]::GetAssemblyName($file).GetPublicKeyToken()
	$publicKeyToken = "";
	if ( $publicKeyTokenArray ) {
		for($i=0; $i -lt $publicKeyTokenArray.Length; $i++) {
			$publicKeyToken += "{0:x2}" -f $publicKeyTokenArray[$i];
		}
	}
		
	if (!$publicKeyToken) {
		Write-Host "Unable to find publicKeyToken for $name (" + $assemblyName.FullName + "), Will abort updating redirects for this item."
		return $false
	}

	$assemblyConfig =  $assemblyConfigs | ? { $_.assemblyIdentity.Name -eq $name -and $_.assemblyIdentity.publicKeyToken -eq $publicKeyToken} 
	if ($assemblyConfig -Eq $null) { 
		$doc = $assemblyBinding.OwnerDocument
		if($doc -eq $null) {
			return $false
		}
		$ns = "urn:schemas-microsoft-com:asm.v1"
		$assemblyConfig = $doc.CreateElement("dependentAssembly",$ns)
		$assemblyIdentity = $doc.CreateElement("assemblyIdentity",$ns)
		$assemblyIdentity.SetAttribute("name",$name)
		$assemblyIdentity.SetAttribute("publicKeyToken",$publicKeyToken)
		$bindingRedirect = $doc.CreateElement("bindingRedirect",$ns)
		$bindingRedirect.SetAttribute("oldVersion","0.0.0.0-"+$assemblyName.Version)
		$bindingRedirect.SetAttribute("newVersion",$assemblyName.Version)
		$assemblyConfig.AppendChild($assemblyIdentity)
		$assemblyConfig.AppendChild($bindingRedirect)
		$assemblyBinding.AppendChild($assemblyConfig)

		Write-Host "Added new assembly redirect for $name" $assemblyName.Version
		return $true
	}

	Write-Host "Updating binding redirects for $name" $assemblyName.Version
	$oldStartInterval = $assemblyConfig.bindingRedirect.oldVersion.Split('-')[0]
	$assemblyConfig.bindingRedirect.oldVersion = $oldStartInterval + "-" + $assemblyName.Version
	$assemblyConfig.bindingRedirect.newVersion = $assemblyName.Version.ToString()
	return $true
}


$libPath = join-path $installPath "lib\net45"
$projectFile = Get-Item $project.FullName
$configPath = join-path $projectFile.Directory.FullName "web.config"

#If web.config file is missing, check if we have an app.config
if(!(test-path $configPath)) {
	$configPath = join-path $projectFile.Directory.FullName "app.config"
	SetCopyToOutputDirectory("imagevault.client.config")	
}

#if we have a config file, update it's assembly references (if any)
if((test-path $configPath)) {

	$config = New-Object xml
	$config.Load($configPath)
	$assemblyBinding = $config.configuration.runtime.assemblyBinding
	$assemblyConfigs = $assemblyBinding.dependentAssembly

	$configModified=$false
	foreach($item in (get-childItem "$libPath\*.dll")) {
		if(UpdateBindingRedirect $item $assemblyBinding $assemblyConfigs) {
			$configModified=$true
		}
	}

	if($configModified) {
		$xmlWriter = $null
		try {
			$xmlWriter = new-object System.Xml.XmlTextWriter($configPath, [System.Text.Encoding]::UTF8)
			$xmlWriter.Formatting = [System.Xml.Formatting]::Indented
			$config.Save($xmlWriter);
		} finally {
			if($xmlWriter -ne $null) {
				$xmlWriter.Close();
			}
		}
	}
}

# SIG # Begin signature block
# MIIZIwYJKoZIhvcNAQcCoIIZFDCCGRACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUInDz+ZwiP1YUw6oliqbTWiyP
# LmWgghQTMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
# AQUFADCBizELMAkGA1UEBhMCWkExFTATBgNVBAgTDFdlc3Rlcm4gQ2FwZTEUMBIG
# A1UEBxMLRHVyYmFudmlsbGUxDzANBgNVBAoTBlRoYXd0ZTEdMBsGA1UECxMUVGhh
# d3RlIENlcnRpZmljYXRpb24xHzAdBgNVBAMTFlRoYXd0ZSBUaW1lc3RhbXBpbmcg
# Q0EwHhcNMTIxMjIxMDAwMDAwWhcNMjAxMjMwMjM1OTU5WjBeMQswCQYDVQQGEwJV
# UzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFu
# dGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMjCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBALGss0lUS5ccEgrYJXmRIlcqb9y4JsRDc2vCvy5Q
# WvsUwnaOQwElQ7Sh4kX06Ld7w3TMIte0lAAC903tv7S3RCRrzV9FO9FEzkMScxeC
# i2m0K8uZHqxyGyZNcR+xMd37UWECU6aq9UksBXhFpS+JzueZ5/6M4lc/PcaS3Er4
# ezPkeQr78HWIQZz/xQNRmarXbJ+TaYdlKYOFwmAUxMjJOxTawIHwHw103pIiq8r3
# +3R8J+b3Sht/p8OeLa6K6qbmqicWfWH3mHERvOJQoUvlXfrlDqcsn6plINPYlujI
# fKVOSET/GeJEB5IL12iEgF1qeGRFzWBGflTBE3zFefHJwXECAwEAAaOB+jCB9zAd
# BgNVHQ4EFgQUX5r1blzMzHSa1N197z/b7EyALt0wMgYIKwYBBQUHAQEEJjAkMCIG
# CCsGAQUFBzABhhZodHRwOi8vb2NzcC50aGF3dGUuY29tMBIGA1UdEwEB/wQIMAYB
# Af8CAQAwPwYDVR0fBDgwNjA0oDKgMIYuaHR0cDovL2NybC50aGF3dGUuY29tL1Ro
# YXd0ZVRpbWVzdGFtcGluZ0NBLmNybDATBgNVHSUEDDAKBggrBgEFBQcDCDAOBgNV
# HQ8BAf8EBAMCAQYwKAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMTEFRpbWVTdGFtcC0y
# MDQ4LTEwDQYJKoZIhvcNAQEFBQADgYEAAwmbj3nvf1kwqu9otfrjCR27T4IGXTdf
# plKfFo3qHJIJRG71betYfDDo+WmNI3MLEm9Hqa45EfgqsZuwGsOO61mWAK3ODE2y
# 0DGmCFwqevzieh1XTKhlGOl5QGIllm7HxzdqgyEIjkHq3dlXPx13SYcqFgZepjhq
# IhKjURmDfrYwggSjMIIDi6ADAgECAhAOz/Q4yP6/NW4E2GqYGxpQMA0GCSqGSIb3
# DQEBBQUAMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3Jh
# dGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBD
# QSAtIEcyMB4XDTEyMTAxODAwMDAwMFoXDTIwMTIyOTIzNTk1OVowYjELMAkGA1UE
# BhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTQwMgYDVQQDEytT
# eW1hbnRlYyBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIFNpZ25lciAtIEc0MIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAomMLOUS4uyOnREm7Dv+h8GEKU5Ow
# mNutLA9KxW7/hjxTVQ8VzgQ/K/2plpbZvmF5C1vJTIZ25eBDSyKV7sIrQ8Gf2Gi0
# jkBP7oU4uRHFI/JkWPAVMm9OV6GuiKQC1yoezUvh3WPVF4kyW7BemVqonShQDhfu
# ltthO0VRHc8SVguSR/yrrvZmPUescHLnkudfzRC5xINklBm9JYDh6NIipdC6Anqh
# d5NbZcPuF3S8QYYq3AhMjJKMkS2ed0QfaNaodHfbDlsyi1aLM73ZY8hJnTrFxeoz
# C9Lxoxv0i77Zs1eLO94Ep3oisiSuLsdwxb5OgyYI+wu9qU+ZCOEQKHKqzQIDAQAB
# o4IBVzCCAVMwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAO
# BgNVHQ8BAf8EBAMCB4AwcwYIKwYBBQUHAQEEZzBlMCoGCCsGAQUFBzABhh5odHRw
# Oi8vdHMtb2NzcC53cy5zeW1hbnRlYy5jb20wNwYIKwYBBQUHMAKGK2h0dHA6Ly90
# cy1haWEud3Muc3ltYW50ZWMuY29tL3Rzcy1jYS1nMi5jZXIwPAYDVR0fBDUwMzAx
# oC+gLYYraHR0cDovL3RzLWNybC53cy5zeW1hbnRlYy5jb20vdHNzLWNhLWcyLmNy
# bDAoBgNVHREEITAfpB0wGzEZMBcGA1UEAxMQVGltZVN0YW1wLTIwNDgtMjAdBgNV
# HQ4EFgQURsZpow5KFB7VTNpSYxc/Xja8DeYwHwYDVR0jBBgwFoAUX5r1blzMzHSa
# 1N197z/b7EyALt0wDQYJKoZIhvcNAQEFBQADggEBAHg7tJEqAEzwj2IwN3ijhCcH
# bxiy3iXcoNSUA6qGTiWfmkADHN3O43nLIWgG2rYytG2/9CwmYzPkSWRtDebDZw73
# BaQ1bHyJFsbpst+y6d0gxnEPzZV03LZc3r03H0N45ni1zSgEIKOq8UvEiCmRDoDR
# EfzdXHZuT14ORUZBbg2w6jiasTraCXEQ/Bx5tIB7rGn0/Zy2DBYr8X9bCT2bW+IW
# yhOBbQAuOA2oKY8s4bL0WqkBrxWcLC9JG9siu8P+eJRRw4axgohd8D20UaF5Mysu
# e7ncIAkTcetqGVvP6KUwVyyJST+5z3/Jvz4iaGNTmr1pdKzFHTx/kuDDvBzYBHUw
# ggVoMIIEUKADAgECAhAO7QrCJlmnO4yBVjj07/rvMA0GCSqGSIb3DQEBBQUAMIG0
# MQswCQYDVQQGEwJVUzEXMBUGA1UEChMOVmVyaVNpZ24sIEluYy4xHzAdBgNVBAsT
# FlZlcmlTaWduIFRydXN0IE5ldHdvcmsxOzA5BgNVBAsTMlRlcm1zIG9mIHVzZSBh
# dCBodHRwczovL3d3dy52ZXJpc2lnbi5jb20vcnBhIChjKTEwMS4wLAYDVQQDEyVW
# ZXJpU2lnbiBDbGFzcyAzIENvZGUgU2lnbmluZyAyMDEwIENBMB4XDTEyMDkwMzAw
# MDAwMFoXDTE1MDkxNTIzNTk1OVowgasxCzAJBgNVBAYTAlNFMQ8wDQYDVQQIEwZT
# d2VkZW4xDzANBgNVBAcTBkthbG1hcjERMA8GA1UEChQITWVyaWRpdW0xPjA8BgNV
# BAsTNURpZ2l0YWwgSUQgQ2xhc3MgMyAtIE1pY3Jvc29mdCBTb2Z0d2FyZSBWYWxp
# ZGF0aW9uIHYyMRQwEgYDVQQLFAtEZXZlbG9wbWVudDERMA8GA1UEAxQITWVyaWRp
# dW0wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQD8A1h6Ak7+Uc+KPe5V
# pmnIzldtC8ZtmHjkF4goC7lakoSuHsBI8pIIc8vD7J19I/kfAoTgi2v3JI8KTysc
# nwTpIRtWzzZu74G9M+X6Mw18cyfSVACpbBGiU0uqS8Yvt2yAP7HZ+3iKwxxt5/au
# kCOS5zPV7oltKvekWNj/xLHFPL6oEpwLd/CKTimAtItMWcu3Go9ozDvnQfrhpu1J
# K0OzOHXaAv6VSgES016gsOO/3k3EaQDOMgm0H4ynttPFbK5Dg0PY2gCzh/a63Y0v
# p7VQdlzOVLR8aLo8spgUkIn5Mxjfsuz+fwGbn9/QFmBw/+IqjZY3m/zFe8YN0Tn5
# wBWbAgMBAAGjggF7MIIBdzAJBgNVHRMEAjAAMA4GA1UdDwEB/wQEAwIHgDBABgNV
# HR8EOTA3MDWgM6Axhi9odHRwOi8vY3NjMy0yMDEwLWNybC52ZXJpc2lnbi5jb20v
# Q1NDMy0yMDEwLmNybDBEBgNVHSAEPTA7MDkGC2CGSAGG+EUBBxcDMCowKAYIKwYB
# BQUHAgEWHGh0dHBzOi8vd3d3LnZlcmlzaWduLmNvbS9ycGEwEwYDVR0lBAwwCgYI
# KwYBBQUHAwMwcQYIKwYBBQUHAQEEZTBjMCQGCCsGAQUFBzABhhhodHRwOi8vb2Nz
# cC52ZXJpc2lnbi5jb20wOwYIKwYBBQUHMAKGL2h0dHA6Ly9jc2MzLTIwMTAtYWlh
# LnZlcmlzaWduLmNvbS9DU0MzLTIwMTAuY2VyMB8GA1UdIwQYMBaAFM+Zqep7JvRL
# yY6P1/AFJu/j0qedMBEGCWCGSAGG+EIBAQQEAwIEEDAWBgorBgEEAYI3AgEbBAgw
# BgEBAAEB/zANBgkqhkiG9w0BAQUFAAOCAQEApHCXF/x9npaNhnFUTc2DFUG3Ykry
# xYdc8xygurLPCWJX+Hkh7/85GSsOYr8TTgDkOYiYokm7nbj95peaYVPPzb116I6f
# U6w0VZcsM5Ed4IDKDclLdcr/PdkjyjWmZ28jgWnfwRyegCc8QTd2DhN/s0bkGLft
# ZzYzeN5kXENaJ9FHvQID8d8XOzWP/b7MfrDL3tb3N7UymXjIG7dMMCX8uoxh2+sa
# RoOJNvofHPEC2pIfyi5GbcDbL/NzLg4EzLewoJfrFiSfg0ZRAnFhOq+ZTiyM4oUd
# mx+YdsfJ3O6V26XwbvM9XIOcVBg/Q0ZggAkyWeqAWQWDBZLUQIfAZgWF+TCCBgow
# ggTyoAMCAQICEFIA5aolVvwahu2WydRLM8cwDQYJKoZIhvcNAQEFBQAwgcoxCzAJ
# BgNVBAYTAlVTMRcwFQYDVQQKEw5WZXJpU2lnbiwgSW5jLjEfMB0GA1UECxMWVmVy
# aVNpZ24gVHJ1c3QgTmV0d29yazE6MDgGA1UECxMxKGMpIDIwMDYgVmVyaVNpZ24s
# IEluYy4gLSBGb3IgYXV0aG9yaXplZCB1c2Ugb25seTFFMEMGA1UEAxM8VmVyaVNp
# Z24gQ2xhc3MgMyBQdWJsaWMgUHJpbWFyeSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0
# eSAtIEc1MB4XDTEwMDIwODAwMDAwMFoXDTIwMDIwNzIzNTk1OVowgbQxCzAJBgNV
# BAYTAlVTMRcwFQYDVQQKEw5WZXJpU2lnbiwgSW5jLjEfMB0GA1UECxMWVmVyaVNp
# Z24gVHJ1c3QgTmV0d29yazE7MDkGA1UECxMyVGVybXMgb2YgdXNlIGF0IGh0dHBz
# Oi8vd3d3LnZlcmlzaWduLmNvbS9ycGEgKGMpMTAxLjAsBgNVBAMTJVZlcmlTaWdu
# IENsYXNzIDMgQ29kZSBTaWduaW5nIDIwMTAgQ0EwggEiMA0GCSqGSIb3DQEBAQUA
# A4IBDwAwggEKAoIBAQD1I0tepdeKuzLp1Ff37+THJn6tGZj+qJ19lPY2axDXdYEw
# fwRof8srdR7NHQiM32mUpzejnHuA4Jnh7jdNX847FO6G1ND1JzW8JQs4p4xjnRej
# CKWrsPvNamKCTNUh2hvZ8eOEO4oqT4VbkAFPyad2EH8nA3y+rn59wd35BbwbSJxp
# 58CkPDxBAD7fluXF5JRx1lUBxwAmSkA8taEmqQynbYCOkCV7z78/HOsvlvrlh3fG
# tVayejtUMFMb32I0/x7R9FqTKIXlTBdOflv9pJOZf9/N76R17+8V9kfn+Bly2C40
# Gqa0p0x+vbtPDD1X8TDWpjaO1oB21xkupc1+NC2JAgMBAAGjggH+MIIB+jASBgNV
# HRMBAf8ECDAGAQH/AgEAMHAGA1UdIARpMGcwZQYLYIZIAYb4RQEHFwMwVjAoBggr
# BgEFBQcCARYcaHR0cHM6Ly93d3cudmVyaXNpZ24uY29tL2NwczAqBggrBgEFBQcC
# AjAeGhxodHRwczovL3d3dy52ZXJpc2lnbi5jb20vcnBhMA4GA1UdDwEB/wQEAwIB
# BjBtBggrBgEFBQcBDARhMF+hXaBbMFkwVzBVFglpbWFnZS9naWYwITAfMAcGBSsO
# AwIaBBSP5dMahqyNjmvDz4Bq1EgYLHsZLjAlFiNodHRwOi8vbG9nby52ZXJpc2ln
# bi5jb20vdnNsb2dvLmdpZjA0BgNVHR8ELTArMCmgJ6AlhiNodHRwOi8vY3JsLnZl
# cmlzaWduLmNvbS9wY2EzLWc1LmNybDA0BggrBgEFBQcBAQQoMCYwJAYIKwYBBQUH
# MAGGGGh0dHA6Ly9vY3NwLnZlcmlzaWduLmNvbTAdBgNVHSUEFjAUBggrBgEFBQcD
# AgYIKwYBBQUHAwMwKAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMTEFZlcmlTaWduTVBL
# SS0yLTgwHQYDVR0OBBYEFM+Zqep7JvRLyY6P1/AFJu/j0qedMB8GA1UdIwQYMBaA
# FH/TZafC3ey78DAJ80M5+gKvMzEzMA0GCSqGSIb3DQEBBQUAA4IBAQBWIuY0pMRh
# y0i5Aa1WqGQP2YyRxLvMDOWteqAif99HOEotbNF/cRp87HCpsfBP5A8MU/oVXv50
# mEkkhYEmHJEUR7BMY4y7oTTUxkXoDYUmcwPQqYxkbdxxkuZFBWAVWVE5/FgUa/7U
# pO15awgMQXLnNyIGCb4j6T9Emh7pYZ3MsZBc/D3SjaxCPWU21LQ9QCiPmxDPIybM
# SyDLkB9djEw0yjzY5TfWb6UgvTTrJtmuDefFmvehtCGRM2+G6Fi7JXx0Dlj+dRtj
# P84xfJuPG5aexVN2hFucrZH6rO2Tul3IIVPCglNjrxINUIcRGz1UUpaKLJw9khoI
# mgUux5OlSJHTMYIEejCCBHYCAQEwgckwgbQxCzAJBgNVBAYTAlVTMRcwFQYDVQQK
# Ew5WZXJpU2lnbiwgSW5jLjEfMB0GA1UECxMWVmVyaVNpZ24gVHJ1c3QgTmV0d29y
# azE7MDkGA1UECxMyVGVybXMgb2YgdXNlIGF0IGh0dHBzOi8vd3d3LnZlcmlzaWdu
# LmNvbS9ycGEgKGMpMTAxLjAsBgNVBAMTJVZlcmlTaWduIENsYXNzIDMgQ29kZSBT
# aWduaW5nIDIwMTAgQ0ECEA7tCsImWac7jIFWOPTv+u8wCQYFKw4DAhoFAKB4MBgG
# CisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcC
# AQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYE
# FPeE1iK6o44LY3upIz0PHt+NnEdzMA0GCSqGSIb3DQEBAQUABIIBAH2J8VkwtTe1
# 0/wEu466pLn8PpXm3NNOGSx299caPp+MWG9WNF3Swrnpp/vTaXKc6/4iBfacUamG
# tDR9zcQLmrU/O27/oq+8B32zqB4gUU7Mp/kFjkMjl6B4coCM8cnV1K+tKdTyQZY6
# lnHUm7EWzsnW0VqKcpcvMweuD9DSH/clrM0nr2uVMMAkrigiaODGYooRV/blHxuq
# LMYKEhYN5a/PY2LnIOXns1jw4d+ZcwQpwa7OafsW7gXvRPP+KyMIXBLrj5j/l6SW
# D9qSsktx4fKG4YEEHOKwJSUW+TOCopQLr9JQejgWqgsOV+2j2LKQMhPwzQ5Tyiv3
# HTqRC68W/OOhggILMIICBwYJKoZIhvcNAQkGMYIB+DCCAfQCAQEwcjBeMQswCQYD
# VQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMT
# J1N5bWFudGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMgIQDs/0OMj+
# vzVuBNhqmBsaUDAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEH
# ATAcBgkqhkiG9w0BCQUxDxcNMTUwNzIzMTAyMTA4WjAjBgkqhkiG9w0BCQQxFgQU
# M0QryXgC+iVQpUNkaGb+A+IVex0wDQYJKoZIhvcNAQEBBQAEggEAFiHyUAJW/hU2
# viuU6y8NXLYP4uUOsV+6Tq2Wr8o91htalcK/PIpeAgyB77bL3FFLVkVompJwXC5n
# 9aFwZvyB1KB0G4zLgaNWB3n4hlq1QDITc+SA1X1P7LZ3kTomI2uTCGD9NbiGfr1d
# OwIoTsVr/LeooXsbCl4GACpIGbh/A6MTtUC5SK5/XrQIZyWkk5O4L1aREYFE7W9b
# QtY13ybk4l1/ZbZtMCGhs9Ha9LbIsD/sUNchVMj/6sbVOsgfOIMImJTMV/3NKvlV
# MiV41Ybi+IyqP0AJUtIa4Pe6mH+TXa7RUJH21YFJRfO3/lZ6svFmSeOFIsB4F56V
# +ARh986Pig==
# SIG # End signature block
