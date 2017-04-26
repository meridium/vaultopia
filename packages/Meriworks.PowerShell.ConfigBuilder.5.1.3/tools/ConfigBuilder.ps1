param([string] $solutionDir, [string] $projectDir, [string] $targetFile, [string] $configuration, [string] $xmlTransformationDllPath, [string] $configBuilderHost)
##Add errorhandling
trap {"Error in ConfigBuilder: $($_.InvocationInfo.PositionMessage)`r`n$($_.Exception.Message)"; exit 1; continue}

Write-Host "ConfigBuilderHost $configBuilderHost"
if(!$configBuilderHost) {
	$configBuilderHost=$env:COMPUTERNAME
}
Write-Host "ConfigBuilderHost $configBuilderHost"

Add-Type -LiteralPath "$xmlTransformationDllPath"

function ExpandVariables($path)
{
	Write-Host "Expanding variables in $(Resolve-Path $path -Relative)"
	(Get-Content -raw $path) -replace "\$\(ProjectDir\)", "$projectDir" -replace "\$\(SolutionDir\)",  "$solutionDir" -replace "\$\(ConfigBuilderHost\)", "$configBuilderHost" |Out-File -Encoding utf8 $path
	Write-Host "done"
}
function XmlDocTransform($xml, $xdt)
{
    if (!$xml -or !(Test-Path -path $xml -PathType Leaf)) {
        throw "File not found. $xml";
    }
    if (!$xdt -or !(Test-Path -path $xdt -PathType Leaf)) {
        throw "File not found. $xdt";
    }

    $xmldoc = New-Object Microsoft.Web.XmlTransform.XmlTransformableDocument;
    $xmldoc.PreserveWhitespace = $true
    $xmldoc.Load($xml);

    $transf = New-Object Microsoft.Web.XmlTransform.XmlTransformation($xdt);
    if ($transf.Apply($xmldoc) -eq $false)
    {
        throw "Transformation failed."
    }
    $xmldoc.Save($xml);
}
function findMergeScripts([string]$baseFile){
	$dir = Split-Path -Parent $baseFile
	$baseFileSegments = $baseFile -split ".base."
	$name = Split-Path -Leaf $baseFileSegments[0]
	#can bee mergeifnewer.config or just config
	$extension = $baseFileSegments[1] -split "\."
	if($extension -is [System.Array]) {
		$extension = $extension[$extension.Length-1]
	}
	$steps = @()
	$steps += (Join-Path $dir "$name.$extension")
	$stepScripts = Get-ChildItem $dir -Name "$name.step.*.xdt"
	foreach($stepScript in $stepScripts) {
		$steps+=(Join-Path $dir $stepScript)
	}
	$hostScript = Join-Path $dir "$($name).host.$configBuilderHost.xdt"
	if(test-path $hostScript) {
		Write-Host "Host merge file found $hostScript"
		$steps +=$hostScript
	}
	return $steps
}

function ShouldMergeBePerformed([string]$targetFile,[string]$baseFile, $mergeFiles,[bool]$keepNewerFiles){
	if(!$keepNewerFiles) {
		return $true
	}
	if(!(Test-Path $targetFile)) {
		Write-Host "Target file is missing"
		return $true
	} 
	if((Get-Item $targetFile).LastWriteTime -lt (Get-Item $baseFile).LastWriteTime) {
		Write-Host "Base file $(Resolve-Path $baseFile -Relative) is newer than target file"
		return $true
	} 
	foreach($mergeFile in $mergeFiles) {
		if((Get-Item $targetFile).LastWriteTime -lt (Get-Item $mergeFile).LastWriteTime) {
			Write-Host "Merge file $(Resolve-Path $mergeFile -Relative) is newer than target file"
			return $true
		}
	}

	Write-Host "Config is not built since target file is newer."
	return $false
}
function PerformMergeLegacy([string] $baseFile, [bool] $keepNewerFiles){
		Write-Host "Warning: Meriworks.PowerShell.ConfigBuilder detected a Legacy naming convention, please change this to the new 5.1 convention. See documentation for more information"

		#get existing target and merge files
		$files = findMergeScripts $baseFile
		if($files -is [system.array]) {
			$targetFile = $files[0]
			$mergeFiles = $files[1..($files.Count-1)]
		} else {
			$targetFile = $files
			$mergeFiles = @()
		}
		Write-Host "Merge Base: $(Resolve-Path $baseFile -Relative)"
		Write-Host "Merge files: $($mergeFiles|Resolve-Path -Relative)"

		#To merge or not to merge, that's the question...
		if(!(ShouldMergeBePerformed $targetFile $baseFile $mergeFiles $keepNewerFiles)) {
			return 
		}

		#copy base config
		Copy-Item $baseFile $targetFile
		#apply transformations
		foreach($mergeFile in $mergeFiles) {
			Write-Host "Applying transform $(Resolve-Path $mergeFile -Relative) to $(Resolve-Path $targetFile -Relative)"
			XmlDocTransform $targetFile $mergeFile
		}
		Write-Host "New config built $(Resolve-Path $targetFile -Relative)"
		ExpandVariables $targetFile

}
function PerformMergeOverwriteExistingLegacy(){
	Process {
		PerformMergeLegacy $_ $false
	}
}
function PerformMergeIfNewerLegacy(){
	Process {
		PerformMergeLegacy $_ $true
	}
}
function PerformReplaceLegacy(){
	Process {
		Write-Host "Warning: Meriworks.PowerShell.ConfigBuilder detected a Legacy naming convention, please change this to the new 5.1 convention. See documentation for more information"
		$baseFile = $_
		Write-Host "Performing replace on $(Resolve-Path $baseFile -Relative)"
		$dir = Split-Path -Parent $baseFile
		$baseFileSegments = $baseFile -split ".base.replace."
		$name = Split-Path -Leaf $baseFileSegments[0]
		$extension = $baseFileSegments[1]
		$hostFile = Join-Path $dir "$name.host.$configBuilderHost.$extension"
		$targetFile = Join-Path $dir "$name.$extension"
		if(test-path $hostFile) {
			Write-Host "Host replace file found $(Resolve-Path $hostFile -Relative)"
			Write-Host "Creating target: $targetFile"
			Copy-Item $hostFile $targetFile -Force
		} else {
			Write-Host "No replacement file found for the current $configBuilderHost, using base instead"
			Copy-Item $baseFile $targetFile -Force
		}
	}
}
function FindBaseMergeFiles {
    Begin{
        $files=@{}
    }
	Process {
		$file = $_
		$baseFileSegments = $_ -split ".merge."
		$file = $baseFileSegments[0] 
        if($files.ContainsKey($file)) {
            return
        }
        $files.Add($file,$file)
        Write-Output $file
	}
}

function PerformMerge {
    Begin{
        Write-Host "PerformMerge starting"
    }
    Process{
        Write-Host "Processing merge of file $_"
        $dir = Split-Path -Parent $_
        $name = Split-Path -Leaf $_
        #create backup to merge with (in case something goes wrong)
        $tempFile = Join-Path $dir "~$name"
        Copy-Item $_ $tempFile

        MergeFile $tempFile "$_.merge.pre.xdt"
	    $stepScripts = Get-ChildItem $dir -Name "$name.merge.step.*.xdt"
	    foreach($stepScript in $stepScripts) {
            MergeFile $tempFile (Join-Path $dir $stepScript)
   	    }
        MergeFile $tempFile "$_.merge.host.$configBuilderHost.xdt"
        MergeFile $tempFile "$_.merge.configuration.$configuration.xdt"
        MergeFile $tempFile "$_.merge.post.xdt"

        Copy-Item $tempFile $_
        Remove-Item $tempFile
    }
}

function MergeFile($baseFile,$mergeFile) {
    if(-not (Test-Path $mergeFile)) {
        return
    }
    Write-Host "Merging with $mergeFile"
    $dir = Split-Path -Parent $mergeFile

    $name= Split-Path -Leaf $mergeFile
    $tempFile = Join-Path $dir "~$name"
    XmlDocTransformAndExpandVariables $baseFile $mergeFile
}

function XmlDocTransformAndExpandVariables($xml, $xdt)
{
    if (!$xml -or !(Test-Path -path $xml -PathType Leaf)) {
        throw "File not found. $xml";
    }
    if (!$xdt -or !(Test-Path -path $xdt -PathType Leaf)) {
        throw "File not found. $xdt";
    }

    $xmldoc = New-Object Microsoft.Web.XmlTransform.XmlTransformableDocument;
    $xmldoc.PreserveWhitespace = $true
    $xmldoc.Load($xml);

    $transformXml = (Get-Content -raw $xdt) -replace "\$\(ProjectDir\)", "$projectDir" -replace "\$\(SolutionDir\)",  "$solutionDir" -replace "\$\(ConfigBuilderHost\)", "$configBuilderHost" 
    $transf = New-Object Microsoft.Web.XmlTransform.XmlTransformation($transformXml,$false,$null);
    if ($transf.Apply($xmldoc) -eq $false)
    {
        throw "Transformation failed."
    }
    $xmldoc.Save($xml);
}
function PerformReplace(){
	Process {
		$defaultFile= $_
		$dir = Split-Path -Parent $defaultFile
		$name = Split-Path -Leaf $defaultFile
		$defaultFileSegments = $name -split ".replace.default."
		$name = Split-Path -Leaf $defaultFileSegments[0]
		$extension = $defaultFileSegments[1]
		$hostFile = Join-Path $dir "$name.replace.host.$configBuilderHost.$extension"
		$targetFile = Join-Path $dir "$name.$extension"
		Write-Host "Performing replace on $(Resolve-Path $targetFile -Relative)"
		if(test-path $hostFile) {
			Write-Host "Host replace file found $(Resolve-Path $hostFile -Relative)"
			Write-Host "Creating target: $targetFile"
			Copy-Item $hostFile $targetFile -Force
		} else {
			Write-Host "No replacement file found for the current $configBuilderHost, using default instead"
			Copy-Item $defaultFile $targetFile -Force
		}
	}
}
Write-Host "Running ConfigBuilder, check https://github.com/meriworks/PowerShell.ConfigBuilder for documentation"
Get-ChildItem $projectDir -Include *.base.config -Recurse|PerformMergeOverwriteExistingLegacy
Get-ChildItem $projectDir -Include *.base.mergeifnewer.config -Recurse|PerformMergeIfNewerLegacy
Get-ChildItem $projectDir -Include *.base.replace.* -Recurse|PerformReplaceLegacy

Get-ChildItem $projectDir -Include *.merge.*.xdt -Recurse|FindBaseMergeFiles|PerformMerge
Get-ChildItem $projectDir -Include *.replace.default.* -Recurse|PerformReplace

# SIG # Begin signature block
# MIIWcAYJKoZIhvcNAQcCoIIWYTCCFl0CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUnGqgGQOiqrzSqL6TfNHFM4nm
# u8egghHAMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
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
# IhKjURmDfrYwggQpMIIDEaADAgECAgsEAAAAAAExicY36DANBgkqhkiG9w0BAQsF
# ADBMMSAwHgYDVQQLExdHbG9iYWxTaWduIFJvb3QgQ0EgLSBSMzETMBEGA1UEChMK
# R2xvYmFsU2lnbjETMBEGA1UEAxMKR2xvYmFsU2lnbjAeFw0xMTA4MDIxMDAwMDBa
# Fw0xOTA4MDIxMDAwMDBaMFoxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxT
# aWduIG52LXNhMTAwLgYDVQQDEydHbG9iYWxTaWduIENvZGVTaWduaW5nIENBIC0g
# U0hBMjU2IC0gRzIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCj79Gf
# KenY04J2PGKg0knWFh7xz/DQukhDAy2nHfIBNEmkEOliE/QT9BaDtdVXQkiGK5VY
# h+ooBHTLchEPYSbh+hxhFccom00Lgg8mK5A6lu2k0GspnPVhiOakV2/u9HDQjRfe
# 5mZ2X3QeXgxTOF2Q9N8wLRsT0XmYVBpLOAT0B8QjA9OSy/eAXaqcVgZELUFMSLQt
# 7DWSmsaV1/XOkDHidrNhuPF1V0KsO84ryJBJ6Lcmz7sMicvQw6NqocnV45xTK1cm
# /laadv1hRqJg7ClGR/LN4IJixgRa5+1OQFxIBn2dX+d0yZ6EZQ1b3tzTJBy0FBHr
# q7/EH6S6mdAXWDXNAgMBAAGjgf0wgfowDgYDVR0PAQH/BAQDAgEGMBIGA1UdEwEB
# /wQIMAYBAf8CAQAwHQYDVR0OBBYEFBlKuFrkTTGlFOVe7C+jHPqAjDJrMEcGA1Ud
# IARAMD4wPAYEVR0gADA0MDIGCCsGAQUFBwIBFiZodHRwczovL3d3dy5nbG9iYWxz
# aWduLmNvbS9yZXBvc2l0b3J5LzA2BgNVHR8ELzAtMCugKaAnhiVodHRwOi8vY3Js
# Lmdsb2JhbHNpZ24ubmV0L3Jvb3QtcjMuY3JsMBMGA1UdJQQMMAoGCCsGAQUFBwMD
# MB8GA1UdIwQYMBaAFI/wS3+oLkUkrk1Q+mOai97i3Ru8MA0GCSqGSIb3DQEBCwUA
# A4IBAQB5sGk04gWH9v7UYCwvhnk0A+CxB5MMhFz55Nxsz2617ApcugvQaDEuP2S9
# D4JrZneBf8YppRfY8IlNgyQR9m7+neFICiig4nskgKTswpoA17BtbM2I1RV4zxP5
# iKVzTcE2K9zLztt+fNKL7y+9s09NOq27Ym4ok8QMy9nmyuARApQDsL0/lChWkB5T
# wifVyTzNGmMeglkVtkDKp4Gqw1WvM9G1degJ6kcISCL7XRvzLHppfsXXWl5WMzyt
# V+iTJULD0l5xO0ocVO2pVawoBcfEbF3cPJP2aTyCUc4aFT1eAXP/QKLqtK7Tjvru
# XWxHx0H11FZX8hg3MtbUzEv2ceB2MIIEozCCA4ugAwIBAgIQDs/0OMj+vzVuBNhq
# mBsaUDANBgkqhkiG9w0BAQUFADBeMQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3lt
# YW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFudGVjIFRpbWUgU3RhbXBp
# bmcgU2VydmljZXMgQ0EgLSBHMjAeFw0xMjEwMTgwMDAwMDBaFw0yMDEyMjkyMzU5
# NTlaMGIxCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3JhdGlv
# bjE0MDIGA1UEAxMrU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBTaWdu
# ZXIgLSBHNDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKJjCzlEuLsj
# p0RJuw7/ofBhClOTsJjbrSwPSsVu/4Y8U1UPFc4EPyv9qZaW2b5heQtbyUyGduXg
# Q0sile7CK0PBn9hotI5AT+6FOLkRxSPyZFjwFTJvTlehroikAtcqHs1L4d1j1ReJ
# MluwXplaqJ0oUA4X7pbbYTtFUR3PElYLkkf8q672Zj1HrHBy55LnX80QucSDZJQZ
# vSWA4ejSIqXQugJ6oXeTW2XD7hd0vEGGKtwITIySjJEtnndEH2jWqHR32w5bMotW
# izO92WPISZ06xcXqMwvS8aMb9Iu+2bNXizveBKd6IrIkri7HcMW+ToMmCPsLvalP
# mQjhEChyqs0CAwEAAaOCAVcwggFTMAwGA1UdEwEB/wQCMAAwFgYDVR0lAQH/BAww
# CgYIKwYBBQUHAwgwDgYDVR0PAQH/BAQDAgeAMHMGCCsGAQUFBwEBBGcwZTAqBggr
# BgEFBQcwAYYeaHR0cDovL3RzLW9jc3Aud3Muc3ltYW50ZWMuY29tMDcGCCsGAQUF
# BzAChitodHRwOi8vdHMtYWlhLndzLnN5bWFudGVjLmNvbS90c3MtY2EtZzIuY2Vy
# MDwGA1UdHwQ1MDMwMaAvoC2GK2h0dHA6Ly90cy1jcmwud3Muc3ltYW50ZWMuY29t
# L3Rzcy1jYS1nMi5jcmwwKAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMTEFRpbWVTdGFt
# cC0yMDQ4LTIwHQYDVR0OBBYEFEbGaaMOShQe1UzaUmMXP142vA3mMB8GA1UdIwQY
# MBaAFF+a9W5czMx0mtTdfe8/2+xMgC7dMA0GCSqGSIb3DQEBBQUAA4IBAQB4O7SR
# KgBM8I9iMDd4o4QnB28Yst4l3KDUlAOqhk4ln5pAAxzdzuN5yyFoBtq2MrRtv/Qs
# JmMz5ElkbQ3mw2cO9wWkNWx8iRbG6bLfsundIMZxD82VdNy2XN69Nx9DeOZ4tc0o
# BCCjqvFLxIgpkQ6A0RH83Vx2bk9eDkVGQW4NsOo4mrE62glxEPwcebSAe6xp9P2c
# tgwWK/F/Wwk9m1viFsoTgW0ALjgNqCmPLOGy9FqpAa8VnCwvSRvbIrvD/niUUcOG
# sYKIXfA9tFGheTMrLnu53CAJE3Hrahlbz+ilMFcsiUk/uc9/yb8+ImhjU5q9aXSs
# xR08f5Lgw7wc2AR1MIIE9jCCA96gAwIBAgIMV4dFLIk72U0QV1UkMA0GCSqGSIb3
# DQEBCwUAMFoxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNh
# MTAwLgYDVQQDEydHbG9iYWxTaWduIENvZGVTaWduaW5nIENBIC0gU0hBMjU2IC0g
# RzIwHhcNMTYwNjMwMDkzNzU0WhcNMTcwOTIxMDk0MzQzWjBxMQswCQYDVQQGEwJT
# RTEPMA0GA1UEBxMGS0FMTUFSMRUwEwYDVQQKEwxNZXJpd29ya3MgQUIxFTATBgNV
# BAMTDE1lcml3b3JrcyBBQjEjMCEGCSqGSIb3DQEJARYUc3VwcG9ydEBtZXJpd29y
# a3Muc2UwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQD5vmRpDIOY/DXa
# g+kGsPGIzksV+kcUAcm0weRPmdxtOJpzZMZlc005fiPS3N0H/SqI7bVuIBG7cFZr
# zP34Kl9Bfejww4Yk0BnR5jlgi1ctUwiDYsibBTR0yTaAwGEFAdoAWMcSfGNnJLja
# EAOqnow763lOxZIHxAO3BVF4D2r+WmlpEOEPjTFGjwuH6cnFZicQvyZAh+qoym6m
# n/6sp6UCcapCmjl7JJ0g8o+K/yLvNiD0w1jELarWdouVUSTANnZEFiE1F8ptfF4n
# 7owHdQtbrJ1gsgRhlG8Wb3gwbnaj3qMbNieTqUl7QaiJz6hsvWKfSkNcwUKSw3qC
# FedXeu5vAgMBAAGjggGjMIIBnzAOBgNVHQ8BAf8EBAMCB4AwgZAGCCsGAQUFBwEB
# BIGDMIGAMEQGCCsGAQUFBzAChjhodHRwOi8vc2VjdXJlLmdsb2JhbHNpZ24uY29t
# L2NhY2VydC9nc2NvZGVzaWduc2hhMmcyLmNydDA4BggrBgEFBQcwAYYsaHR0cDov
# L29jc3AyLmdsb2JhbHNpZ24uY29tL2dzY29kZXNpZ25zaGEyZzIwVgYDVR0gBE8w
# TTBBBgkrBgEEAaAyATIwNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFs
# c2lnbi5jb20vcmVwb3NpdG9yeS8wCAYGZ4EMAQQBMAkGA1UdEwQCMAAwQgYDVR0f
# BDswOTA3oDWgM4YxaHR0cDovL2NybC5nbG9iYWxzaWduLmNvbS9ncy9nc2NvZGVz
# aWduc2hhMmcyLmNybDATBgNVHSUEDDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQU1tPG
# th3Qmzaihnlnk0lklbe6X6UwHwYDVR0jBBgwFoAUGUq4WuRNMaUU5V7sL6Mc+oCM
# MmswDQYJKoZIhvcNAQELBQADggEBAFe7R/lMQasxSC/5VjxB3nSXS3OzNffaOSkX
# TYq7Sff+dgV3L6DxdezhnSoRHpYNM7lgTHdyhgsEV2kk/r552jfyRbM/MEixzTEo
# TUgGdXXBPFdCDC0YZGZ6/duk4Ht4ns+bKrFLu44ec6Kfe1Uv3HlOPC/BwrstTsO7
# 3CEDKhbBv0pwLAqv+vMiVemuE5GUiwtTTa76REUR84aeZAUI25yfd7V9exA1uZp2
# boBasx/vf8ysJPKqEgsoqwgB9rGPOCsWmUF1RswkQwMnEUYYmmc4nqZn5s0lGzBE
# onQ3pKkw8sXK9u6i8TohdGeXYkb4G1Nme1bYSWEi4fos8hMcIi0xggQaMIIEFgIB
# ATBqMFoxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMTAw
# LgYDVQQDEydHbG9iYWxTaWduIENvZGVTaWduaW5nIENBIC0gU0hBMjU2IC0gRzIC
# DFeHRSyJO9lNEFdVJDAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAA
# oQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4w
# DAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUMibCyLx5XuYnnXrW6nG8itxS
# Ea4wDQYJKoZIhvcNAQEBBQAEggEAR+jUbyaTRtoT9DH0kbzstaeNvJ4lkAnRfZx0
# ISlVqCRp5jy3SIBrtzEh0ezavWR8DxIVz0V5MjDPw5TXYaxkLfOgRDWCJu006D6g
# ypXIrCZ7B2VwZBNpJAcrTsbjdEJ1LCAAZta1DMMU15e/Xdn9jj/MOVXS1hKQVp+w
# +mrDVVyZZTV2narh4ZogRUOJggNqkFUtpQHHQV3PMx2xvUZJsEFq1hn/qfDXFmUh
# Y+PkHHM132hESo3/uO2ZJHCVhyZqNyAuf08rVgkeg7KU9qNrrbYEHzmEM28vFfe8
# d/pJBAHZdFeuVr1s/bcBVWHmjTWXMxweqKjRzdPd2cpJNqAbEKGCAgswggIHBgkq
# hkiG9w0BCQYxggH4MIIB9AIBATByMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRT
# eW1hbnRlYyBDb3Jwb3JhdGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFt
# cGluZyBTZXJ2aWNlcyBDQSAtIEcyAhAOz/Q4yP6/NW4E2GqYGxpQMAkGBSsOAwIa
# BQCgXTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0x
# NjEwMjAwNzAwMTNaMCMGCSqGSIb3DQEJBDEWBBQ92EYodRyqIcIDw1QZd31YSuSW
# fzANBgkqhkiG9w0BAQEFAASCAQBfVfH2Z018v3LsMHTKka0sOGoW1jtr6/N/ZBoP
# uRA2LlWwTBg+g7n9kG5/agUFkdJZdM0xv8uo8ZlBjb9SQFT5k2F+ml2ctNGc/40d
# KdpBmbrxI+nAZeBPwTFtSfAomBDj+0rnbOXWGLL1XEB/QMwRkiMU/mzAW5XSuE7S
# ZvAesL1uztVfZkVMN79bCv0CFMZ5kJAaHki/novcbGfGTgfACmrWpJ2qThc6aMZG
# 42T1SD6y70SKvJUaS8A81crzFdARnbQURYeIihWyTuIyp5PJKHOuF59IZlPUlJ/g
# zMsN5gmCF9BQZbDHhvA8XzYmWPoqN5wmU9Ipbn/boHDK+MJY
# SIG # End signature block
