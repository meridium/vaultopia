#$installPath is the path to the folder where the package is installed
param([string]$installPath)
#
#   Argument#1 is the path of the web-root
#   Extract the connectionstring from the web.config...
#

Function Update-ProcessMapProperties() {

    Write-Host "Performing Update of ProcessMap properties in EPiServer"
    #Gets the current project
    $project = Get-Project
    $projectPath = Get-ChildItem $project.Fullname
    $webRootPath = $projectPath.Directory.FullName
    $webConfig = join-path -path $webRootPath -childpath "web.config" 

    if(!(Test-Path -Path $webConfig)) {
        throw "web.config file does not exist - No database information available"
    }
    else {
        Write-Verbose "Parsing $webConfig"
        $xml = [xml](get-content $webConfig)

        if($xml.configuration.connectionStrings.configSource -ne $null) {
            $connectionStringConfig = join-path -path $webRootPath -childpath $xml.configuration.connectionStrings.configSource
            $connectionStringsXml = [xml](get-content $connectionStringConfig)
            $connectionString = ($connectionStringsXml.connectionStrings.add | Where-Object { $_.name -eq "EPiServerDB" }).GetAttribute("connectionString")
        } else {
            $connectionString = ($xml.configuration.connectionStrings.add | Where-Object { $_.name -eq "EPiServerDB" }).GetAttribute("connectionString")
        }
        
        if($connectionString -eq $null) {
            throw "No connectionstring was found"
        }
    }
    #
    #   Open a connection and execute the script
    #
    $sqlFile = join-path -path $installPath -childpath "epiupdates\sql\UpgradeProcessMapEPi7.sql"
    Try {
		#Since connection string can contain the DataDirectory domain data, we need to set it.
		$dataDir = join-path -path $webRootPath -childpath "App_Data"
		[System.AppDomain]::CurrentDomain.SetData("DataDirectory","$dataDir")

        $Conn = new-object System.Data.SqlClient.SqlConnection
        $Conn.ConnectionString = $connectionString
        $DataCmd = New-Object System.Data.SqlClient.SqlCommand;
        [string]$MyQuery = (Get-Content $sqlFile) -join "`n";
		$sqlStatements = [regex]::split($MyQuery,"`n\s*GO\s*`n") 
		$dbCompleted = $false
		$DataCmd.Connection = $Conn;
		$Conn.Open()|out-null
		
		for( $i=0;$i -le $sqlStatements.Length;$i++) {
			$sql = $sqlStatements[$i];
			if([System.String]::IsNullOrWhiteSpace($sql)) {
				continue;
			}
			Write-Verbose $sql
			$DataCmd.CommandText = $sql;
			if($i -eq 0) {
				$reader = $DataCmd.ExecuteReader();
				$reader.Read()|out-null
				$retVal = $reader.GetInt32(0)
				$message = $reader.GetString(1)
				$reader.Close();
				$reader.Dispose();
				if($retVal -eq 0) {#no upgrade necessary
					Write-Host "$message"
					break;
				} elseif ($retVal -eq 1) {#Upgrade needed
					Write-Host "$message"
					continue;
				} else { #No episerver database
					Write-Host "$message" -backgroundColor "red" -foregroundcolor "white"
					break;
				}
			} else {
				$ret = $DataCmd.ExecuteNonQuery();	
				$dbCompleted = $true
			}
		}
		if($dbCompleted) {
			Write-Host "ProcessMap properties from EPiServer 7 was successfully updated to EPiServer 8." -backgroundColor "green" -foregroundcolor "black"
		}
    } Catch {
        $errorMessage = $_.Exception.Message

		Write-Host "Automatic remap of ProcessMap Properties in EPiServer failed" -backgroundColor "red" -foregroundcolor "white"
		Write-Host "$errorMessage" -backgroundColor "red" -foregroundcolor "white"
		Write-Host "The Package will be installed anyway but you can run the update script manually in the EPiServer database." -backgroundColor "yellow" -foregroundcolor "black"
		Write-Host "The script is located $sqlFile" -backgroundColor "green" -foregroundcolor "black"
    } Finally {
        $Conn.Close();
        $Conn.Dispose();
    }
}


# SIG # Begin signature block
# MIIWcgYJKoZIhvcNAQcCoIIWYzCCFl8CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUfTaU0WHhCxxpIom8bNGrMKSD
# 4+ygghG8MIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
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
# xR08f5Lgw7wc2AR1MIIE8jCCA9qgAwIBAgISESGb6pUe9TyQe8SCqa0GnM+dMA0G
# CSqGSIb3DQEBCwUAMFoxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWdu
# IG52LXNhMTAwLgYDVQQDEydHbG9iYWxTaWduIENvZGVTaWduaW5nIENBIC0gU0hB
# MjU2IC0gRzIwHhcNMTUwODIxMDk0MzQzWhcNMTYwODIxMDk0MzQzWjBxMQswCQYD
# VQQGEwJTRTEPMA0GA1UEBxMGS0FMTUFSMRUwEwYDVQQKEwxNZXJpd29ya3MgQUIx
# FTATBgNVBAMTDE1lcml3b3JrcyBBQjEjMCEGCSqGSIb3DQEJARYUc3VwcG9ydEBt
# ZXJpd29ya3Muc2UwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCStj1I
# a3OQQJt9RjId5fR2g/wifXSvNF0fKRsgfsFk13aNcgE084sVnURHg3TkOFaP5aLx
# Zzvq9OzqVFFzLtolaXNNNiogGXcaROHSd35VOqDZw2ufQNyYxpzQhjWKmyJp9AS4
# DJ3IYX697dWwF8tUy04A27LuKCKf+3OvQNypDqD4EeQfj7WkGazinTvcbJoYltqj
# h6hsKbVxol/IGWbRSMmspneQ/dzVCyTr8BLcPQRUOhn17bozeYABncm/LcAI1O0S
# vvPBMtObWvVs6oWzT3OvShkpmFXBisLDspYizffhpVASr8WOlvPGJxaiusbmXkNd
# FisEVvKfACkYd1s7AgMBAAGjggGZMIIBlTAOBgNVHQ8BAf8EBAMCB4AwTAYDVR0g
# BEUwQzBBBgkrBgEEAaAyATIwNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xv
# YmFsc2lnbi5jb20vcmVwb3NpdG9yeS8wCQYDVR0TBAIwADATBgNVHSUEDDAKBggr
# BgEFBQcDAzBCBgNVHR8EOzA5MDegNaAzhjFodHRwOi8vY3JsLmdsb2JhbHNpZ24u
# Y29tL2dzL2dzY29kZXNpZ25zaGEyZzIuY3JsMIGQBggrBgEFBQcBAQSBgzCBgDBE
# BggrBgEFBQcwAoY4aHR0cDovL3NlY3VyZS5nbG9iYWxzaWduLmNvbS9jYWNlcnQv
# Z3Njb2Rlc2lnbnNoYTJnMi5jcnQwOAYIKwYBBQUHMAGGLGh0dHA6Ly9vY3NwMi5n
# bG9iYWxzaWduLmNvbS9nc2NvZGVzaWduc2hhMmcyMB0GA1UdDgQWBBRTbzD4nfyp
# ticu3RnQ+cYaFSXRIDAfBgNVHSMEGDAWgBQZSrha5E0xpRTlXuwvoxz6gIwyazAN
# BgkqhkiG9w0BAQsFAAOCAQEAGhMgIaMm/55Eovw9kSwRMuDt+LBtQ3p2xE8KTEaW
# Qxs+YdRgsb3zpe5BlZXeU8xnkOth3PGpeZ6xWWDmQ875lzqQiYQ3xrAQqyqx77ev
# Zg/cLN7DufOOx4ugAgZ1Im/kgK31vu1RiIsZP54GsuUtHonPiofyWWm4oM4Wu8WH
# 0NQ824phwbjHpIu6zYIsIVCgL7pDMoIpSUIAgYpdug2DQkEnOMdsZSV+bQVrmObi
# W8ViRSDe1E2mvZ23zHUPUAqGzxs/MxT0kmqxeUAxft1vpXxNDMbP1q2Kbifg0+Cq
# zW6cV+TL4YKFKnV9/iPOoqWFXQD33q/vU3yppdlR7SKRUTGCBCAwggQcAgEBMHAw
# WjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExMDAuBgNV
# BAMTJ0dsb2JhbFNpZ24gQ29kZVNpZ25pbmcgQ0EgLSBTSEEyNTYgLSBHMgISESGb
# 6pUe9TyQe8SCqa0GnM+dMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEMMQowCKAC
# gAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsx
# DjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBSjqsdCesZu4U+P6TYk0paz
# cZntOjANBgkqhkiG9w0BAQEFAASCAQALSGJJT/mpOG7BDco2yNK0IYOW86v6vzrr
# Ql2lQQ9KStUsxRO4jkuNrUZjLOX3kytjFfPNzBnGxCCEnRJTO+Vcquvb3GlFD5qC
# IodekVhst6wIj3qPuSh4BP1oe1gO3y6Dk4ijIufxF1LaWRFIrcabf4DygRDZUvKy
# vR7IDNwnZdl6ri1u/enMt0WmKYdTGVSX3Ce8t+O27oBX7MX66MaAOSjdhPb4vNgc
# YC+rDfZkq6yK2hnwCVJVFE1H/kkQt+c6wKHqgDzAqZLNiIRNz0VkJzwLAiW3rnO9
# MHoYlC/e6fb2kse24pm7V7dIDAMznsLDCrtqmldVbKPpqCOP6TRCoYICCzCCAgcG
# CSqGSIb3DQEJBjGCAfgwggH0AgEBMHIwXjELMAkGA1UEBhMCVVMxHTAbBgNVBAoT
# FFN5bWFudGVjIENvcnBvcmF0aW9uMTAwLgYDVQQDEydTeW1hbnRlYyBUaW1lIFN0
# YW1waW5nIFNlcnZpY2VzIENBIC0gRzICEA7P9DjI/r81bgTYapgbGlAwCQYFKw4D
# AhoFAKBdMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8X
# DTE1MDkwMzA5MTMxM1owIwYJKoZIhvcNAQkEMRYEFE15LMJbHXzi30tDlUXf4bk2
# OLANMA0GCSqGSIb3DQEBAQUABIIBAG6+4QS/S9jXd/KQGnrDXgNnoLAYSvYKe8Zh
# CZFgLDa/T1shipNXpDGhJf89kU1W4dldp5ORE8uqWQIdRdcJue3ALy2grWU41UEw
# LTdW2RbXZqZyFmPmD9FTu4x1mUB5yU9J1AiC9NCUoPp9z8U5CkbMeSflOmLRcevW
# Kh4ysLLEbr20ryAVAgRQ6xJ2SHW2OUr3wQnN3hI5n/nEqg82+OYjhe054EaXHbKh
# dTDcMFV1y/6ScY7C8xe6LgaUt1Bc1DeWSr4eLmeWU9mIZfLFXA2rPWsxMiY4wLH2
# 0Q9s7HxI3381OihSxQv51ATClt201/1LNau4Slpch2qwMb7/UuQ=
# SIG # End signature block
