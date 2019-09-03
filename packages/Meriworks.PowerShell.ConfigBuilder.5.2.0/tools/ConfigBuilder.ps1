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
        MergeFile $tempFile "$_.merge.xdt"
	    $stepScripts = Get-ChildItem $dir -Name "$name.merge.step.*.xdt"
	    foreach($stepScript in $stepScripts) {
            MergeFile $tempFile (Join-Path $dir $stepScript)
   	    }
        MergeFile $tempFile "$_.merge.host.$configBuilderHost.xdt"
        MergeFile $tempFile "$_.merge.configuration.$configuration.xdt"
        MergeFile $tempFile "$_.merge.post.xdt"

        if(Compare-Object -ReferenceObject $(Get-Content $_) -DifferenceObject $(Get-Content $tempFile)) {
			Write-Host "Updating merge file $_"
			Copy-Item $tempFile $_
		} else {
			Write-Host "Merge produced no changes"
		}
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
			if(Compare-Object -ReferenceObject $(Get-Content $targetFile) -DifferenceObject $(Get-Content $hostFile)) {
				Write-Host "Creating target: $targetFile"
				Copy-Item $hostFile $targetFile -Force
			} else {
				Write-Host "Target already matches host file, no replacement necessary"
			}
		} else {
			Write-Host "No replacement file found for the current $configBuilderHost, using default instead"
			if(Compare-Object -ReferenceObject $(Get-Content $targetFile) -DifferenceObject $(Get-Content $defaultFile)) {
				Write-Host "Creating target: $targetFile"
				Copy-Item $defaultFile $targetFile -Force
			} else {
				Write-Host "Target already matches default file, no replacement necessary"
			}

		}
	}
}
Write-Host "Running ConfigBuilder, check https://github.com/meriworks/PowerShell.ConfigBuilder for documentation"
Get-ChildItem $projectDir -Include *.base.config -Recurse|PerformMergeOverwriteExistingLegacy
Get-ChildItem $projectDir -Include *.base.mergeifnewer.config -Recurse|PerformMergeIfNewerLegacy
Get-ChildItem $projectDir -Include *.base.replace.* -Recurse|PerformReplaceLegacy

Get-ChildItem $projectDir -Include *.merge.*xdt -Recurse|FindBaseMergeFiles|PerformMerge
Get-ChildItem $projectDir -Include *.replace.default.* -Recurse|PerformReplace

# SIG # Begin signature block
# MIIW3AYJKoZIhvcNAQcCoIIWzTCCFskCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUURzQ/44ljF/VRxRGFM4bPGpc
# XfCgghIsMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
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
# IhKjURmDfrYwggSUMIIDfKADAgECAg5IG2oHJtLoPyYC1IJazTANBgkqhkiG9w0B
# AQsFADBMMSAwHgYDVQQLExdHbG9iYWxTaWduIFJvb3QgQ0EgLSBSMzETMBEGA1UE
# ChMKR2xvYmFsU2lnbjETMBEGA1UEAxMKR2xvYmFsU2lnbjAeFw0xNjA2MTUwMDAw
# MDBaFw0yNDA2MTUwMDAwMDBaMFoxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9i
# YWxTaWduIG52LXNhMTAwLgYDVQQDEydHbG9iYWxTaWduIENvZGVTaWduaW5nIENB
# IC0gU0hBMjU2IC0gRzMwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCN
# hVUjqR9Tr8ntNsIptW7Y+UL1IYuH8EOhL8A/l+MYR9SWToirxmPptkkVhfHZm3sb
# /dhKzG1OhkAXzXu6Ryi11hRADIbuHksz8yxV7iGM2rbB/rBOOq5Rn6UU4xDmk8r6
# +V2xkIfv+DUt/KJcJu57FYsf2cOhlzVBszD9chOtkZc6znKdBgp1PB+Y48sYL4yf
# CEqRCtnZNdmDknZiXt+DruTWAU7M8zxwYVg3HxTjaqCva/TZ0mwsGTBdoG9S39Gc
# yeAN2XURZZbZQ7SnkDmuRxxUy7GVbiXejvESHPDXbucUTbMaZdaESlfuBK9iOMUQ
# m0OOUrg+tq6eLJf/jnTvAgMBAAGjggFkMIIBYDAOBgNVHQ8BAf8EBAMCAQYwHQYD
# VR0lBBYwFAYIKwYBBQUHAwMGCCsGAQUFBwMJMBIGA1UdEwEB/wQIMAYBAf8CAQAw
# HQYDVR0OBBYEFA8656yUkXQtlgJzg62cLkk/GapUMB8GA1UdIwQYMBaAFI/wS3+o
# LkUkrk1Q+mOai97i3Ru8MD4GCCsGAQUFBwEBBDIwMDAuBggrBgEFBQcwAYYiaHR0
# cDovL29jc3AyLmdsb2JhbHNpZ24uY29tL3Jvb3RyMzA2BgNVHR8ELzAtMCugKaAn
# hiVodHRwOi8vY3JsLmdsb2JhbHNpZ24uY29tL3Jvb3QtcjMuY3JsMGMGA1UdIARc
# MFowCwYJKwYBBAGgMgEyMAgGBmeBDAEEATBBBgkrBgEEAaAyAV8wNDAyBggrBgEF
# BQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFsc2lnbi5jb20vcmVwb3NpdG9yeS8wDQYJ
# KoZIhvcNAQELBQADggEBABWEKAztocMZgttjJ0HXzGN91rzPNpvP0l1MAotYGhYI
# erGYmX/YM4pcnmIKmuqQwsVjBAvoh1gGAAeCWcOolDLZ4BRNoNUj4MfduvBp4kpF
# ZS1NSZB4ZjIOsGjAsIiwju1cBvhcEEg/I3O6O1OEUoDN8LMVyBEKiwV4RlkI1L63
# /0v1nGpMnHaiEYVFjNQ37lDd4TM0qaEfOgvxVkSKb7Mz0LGO0QxgB+4ywvAkb7+v
# +4EBdmfEo+jgq9wzVSjjZ0c862qk35Tp9KbAgdFSmFGm1gK3POpK79C6ZdI3g1NL
# fmd8jED2BxywrwQG3PhsRohynOtOncOwuVSjuU6XyhQwggSjMIIDi6ADAgECAhAO
# z/Q4yP6/NW4E2GqYGxpQMA0GCSqGSIb3DQEBBQUAMF4xCzAJBgNVBAYTAlVTMR0w
# GwYDVQQKExRTeW1hbnRlYyBDb3Jwb3JhdGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMg
# VGltZSBTdGFtcGluZyBTZXJ2aWNlcyBDQSAtIEcyMB4XDTEyMTAxODAwMDAwMFoX
# DTIwMTIyOTIzNTk1OVowYjELMAkGA1UEBhMCVVMxHTAbBgNVBAoTFFN5bWFudGVj
# IENvcnBvcmF0aW9uMTQwMgYDVQQDEytTeW1hbnRlYyBUaW1lIFN0YW1waW5nIFNl
# cnZpY2VzIFNpZ25lciAtIEc0MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
# AQEAomMLOUS4uyOnREm7Dv+h8GEKU5OwmNutLA9KxW7/hjxTVQ8VzgQ/K/2plpbZ
# vmF5C1vJTIZ25eBDSyKV7sIrQ8Gf2Gi0jkBP7oU4uRHFI/JkWPAVMm9OV6GuiKQC
# 1yoezUvh3WPVF4kyW7BemVqonShQDhfultthO0VRHc8SVguSR/yrrvZmPUescHLn
# kudfzRC5xINklBm9JYDh6NIipdC6Anqhd5NbZcPuF3S8QYYq3AhMjJKMkS2ed0Qf
# aNaodHfbDlsyi1aLM73ZY8hJnTrFxeozC9Lxoxv0i77Zs1eLO94Ep3oisiSuLsdw
# xb5OgyYI+wu9qU+ZCOEQKHKqzQIDAQABo4IBVzCCAVMwDAYDVR0TAQH/BAIwADAW
# BgNVHSUBAf8EDDAKBggrBgEFBQcDCDAOBgNVHQ8BAf8EBAMCB4AwcwYIKwYBBQUH
# AQEEZzBlMCoGCCsGAQUFBzABhh5odHRwOi8vdHMtb2NzcC53cy5zeW1hbnRlYy5j
# b20wNwYIKwYBBQUHMAKGK2h0dHA6Ly90cy1haWEud3Muc3ltYW50ZWMuY29tL3Rz
# cy1jYS1nMi5jZXIwPAYDVR0fBDUwMzAxoC+gLYYraHR0cDovL3RzLWNybC53cy5z
# eW1hbnRlYy5jb20vdHNzLWNhLWcyLmNybDAoBgNVHREEITAfpB0wGzEZMBcGA1UE
# AxMQVGltZVN0YW1wLTIwNDgtMjAdBgNVHQ4EFgQURsZpow5KFB7VTNpSYxc/Xja8
# DeYwHwYDVR0jBBgwFoAUX5r1blzMzHSa1N197z/b7EyALt0wDQYJKoZIhvcNAQEF
# BQADggEBAHg7tJEqAEzwj2IwN3ijhCcHbxiy3iXcoNSUA6qGTiWfmkADHN3O43nL
# IWgG2rYytG2/9CwmYzPkSWRtDebDZw73BaQ1bHyJFsbpst+y6d0gxnEPzZV03LZc
# 3r03H0N45ni1zSgEIKOq8UvEiCmRDoDREfzdXHZuT14ORUZBbg2w6jiasTraCXEQ
# /Bx5tIB7rGn0/Zy2DBYr8X9bCT2bW+IWyhOBbQAuOA2oKY8s4bL0WqkBrxWcLC9J
# G9siu8P+eJRRw4axgohd8D20UaF5Mysue7ncIAkTcetqGVvP6KUwVyyJST+5z3/J
# vz4iaGNTmr1pdKzFHTx/kuDDvBzYBHUwggT3MIID36ADAgECAgwp7JJ2dLOukR0K
# xh8wDQYJKoZIhvcNAQELBQAwWjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2Jh
# bFNpZ24gbnYtc2ExMDAuBgNVBAMTJ0dsb2JhbFNpZ24gQ29kZVNpZ25pbmcgQ0Eg
# LSBTSEEyNTYgLSBHMzAeFw0xODA5MDQxMjQ1MzlaFw0yMDExMjEwOTQzNDNaMHEx
# CzAJBgNVBAYTAlNFMQ8wDQYDVQQHEwZLQUxNQVIxFTATBgNVBAoTDE1lcml3b3Jr
# cyBBQjEVMBMGA1UEAxMMTWVyaXdvcmtzIEFCMSMwIQYJKoZIhvcNAQkBFhRzdXBw
# b3J0QG1lcml3b3Jrcy5zZTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
# AKr/K9JMIuIOjaQ8OJGFz/SKsPuUfwqGvDvhkv+IT5nYKAYS8M0h4qkQVc1CX9Vh
# zRi/97HI74cyC9snuWUtjea6eQpcO/Pp0odcNUKDEhSQeDswbXPVCXCcxsQsJX3L
# bv5FWuNSuWKWWw1WXtjD3/TCxQ2kRUPq4YsJdW+8yYePQk3k19r56BL9hKU7hrSI
# aYaNAWf8u78alqgr1dOPOV99SVy5u75RaMZr9gSwU+lXZk3DFk5MMeJPmd4CExuZ
# jvIDON2+1a2YfYDPs2a3lnnghIzbbru8408SQOzqtLek4UkOCDdg3fCEi6+R6d6h
# bA+qK0Hmv89Wcnly4x7xYqECAwEAAaOCAaQwggGgMA4GA1UdDwEB/wQEAwIHgDCB
# lAYIKwYBBQUHAQEEgYcwgYQwSAYIKwYBBQUHMAKGPGh0dHA6Ly9zZWN1cmUuZ2xv
# YmFsc2lnbi5jb20vY2FjZXJ0L2dzY29kZXNpZ25zaGEyZzNvY3NwLmNydDA4Bggr
# BgEFBQcwAYYsaHR0cDovL29jc3AyLmdsb2JhbHNpZ24uY29tL2dzY29kZXNpZ25z
# aGEyZzMwVgYDVR0gBE8wTTBBBgkrBgEEAaAyATIwNDAyBggrBgEFBQcCARYmaHR0
# cHM6Ly93d3cuZ2xvYmFsc2lnbi5jb20vcmVwb3NpdG9yeS8wCAYGZ4EMAQQBMAkG
# A1UdEwQCMAAwPwYDVR0fBDgwNjA0oDKgMIYuaHR0cDovL2NybC5nbG9iYWxzaWdu
# LmNvbS9nc2NvZGVzaWduc2hhMmczLmNybDATBgNVHSUEDDAKBggrBgEFBQcDAzAd
# BgNVHQ4EFgQUHFblxHD+1HUd5sblnoDajFAG8i4wHwYDVR0jBBgwFoAUDzrnrJSR
# dC2WAnODrZwuST8ZqlQwDQYJKoZIhvcNAQELBQADggEBAAZvOcATRr427lRP/qEB
# P5EBuEvPvn1QNQ/qxdR59NYrep7h2mGwgzf0aHr3lI/4KpyQP2S0guJb7tAzYXMv
# eLxciQQL1a0tGM+wIuLTAdx/DE8ETfD4Pp2wBYAwsDAzog+nkwsq1q6xFb+qLsiL
# 42kRuZd0r3gwiulf4NrN/wXNAMmC+1kiQG6pVzcJnSWTud397W1STGFP73DHMk3o
# 9GMR1M1Hl/fFMCRwJh0j6Cta0gHw/PcdRJzly7qg5Z5N/LcpB06X/NL+kl6gcMVE
# 5EakcHiOaFpbCyHEZkpyIuiK51Q3sdKUWTvt17ZYZwx1CFH5AJ0Sl/TwTJ3L2oJf
# bScxggQaMIIEFgIBATBqMFoxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxT
# aWduIG52LXNhMTAwLgYDVQQDEydHbG9iYWxTaWduIENvZGVTaWduaW5nIENBIC0g
# U0hBMjU2IC0gRzMCDCnsknZ0s66RHQrGHzAJBgUrDgMCGgUAoHgwGAYKKwYBBAGC
# NwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUHHVSfiqj
# U6TsPQ1MHR/aB1XUeR0wDQYJKoZIhvcNAQEBBQAEggEARe5FCp0TV7RGDFSpoxCr
# Y2MgqrMrRzILLjHb6RBVLID3Br3LffZQVFKH4Ld7JadGdZ/eOysnu63UT5x/Y+8e
# 9YDR/AiMyEHRjO1FQCVUi9DPSl3x1IxUVV6avpLcAoEm1PloiZk1H/3MwTCVCp2v
# au7PCViwpALh/d39nFEIi2goJqCn5BWI52BOHAoaYwjYNABIapzhRJkExzpxx+x/
# ctgfGQClKNLQyH3AVgjD4YFOjSFWhIRiVwdyMza7fqmQE+mkQKam3zdy131qpNqJ
# TtQlVowvQdIGYDdWNhoH0k2cBRjb4CZuYpotWF3ZY1PwInBUTNscmS66SPusfprU
# YKGCAgswggIHBgkqhkiG9w0BCQYxggH4MIIB9AIBATByMF4xCzAJBgNVBAYTAlVT
# MR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3JhdGlvbjEwMC4GA1UEAxMnU3ltYW50
# ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBDQSAtIEcyAhAOz/Q4yP6/NW4E2GqY
# GxpQMAkGBSsOAwIaBQCgXTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqG
# SIb3DQEJBTEPFw0xOTA0MDEwODA3MTFaMCMGCSqGSIb3DQEJBDEWBBTw8ZPj28qe
# OzkVMLsIuRfxVw1wfTANBgkqhkiG9w0BAQEFAASCAQCFgh8DYV2ac0SRSXp556k7
# VEaFjyRiWHKnU7ot/UNHsMxoSwBpfv7RbYL3za1TsmYbtORizQitlX0OQBX7smlZ
# +qiHlY8f8xacsVjCM5d+b+baCh9AJXbaOTqDMDfgUa0ietj7R3rBIOXfLWk9XziF
# HK5U7ZV/TDs136OnMW1mwBv9Cl7wOfutnXklzu7B2y1mNQrQgzZSBOjQbYYbbTbu
# zdzkR5uEfaP55I2kVpegjUuH53ylgo0lTTFIIETxLQTI+//jzGk3vP8XMikaWQb0
# vI6PdwQ8lMNp0XFJcA6/2fDgwrCFsLwL8Z5sQiBaKdpfgcJFiFlRiDUC1JoiyGeE
# SIG # End signature block
