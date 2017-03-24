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
# MIIWcAYJKoZIhvcNAQcCoIIWYTCCFl0CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUA0AEyV9HlxQceYYBAZCAE/AE
# IhugghHAMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
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
# DAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQU9xm/cGsaev2mPvIDowHKLqnx
# /kQwDQYJKoZIhvcNAQEBBQAEggEAv+sMPUkFcdS2eNF0KWMKWtYAi51O/gOvSlXu
# oGczsqbHjhxqJ/7M8xdjKvmsEbLM41QIpvl/h02Vasm7m688gHxyqwb2W2nyqF5/
# qXn6sWIEzQRghsBfmc+nh05T2vna4ja11lWa6JqTVeop22sadC12vggwtRpa11GO
# cYFtxqToRiWPI7M4eIw623jfXpxVaZnMYOIv1PODLypaaUMd0bWAnJ4DmnI2n6uy
# fQ+KAAQ20TOwmkr3+DNcoaKKlXedgLHptkZbOe0CcRRrL9qt4g4BDk+jPXabw4xr
# CbA1KBMXrzJj2K7WDutommTh6cYaOUqeyoOSdghvGOxRdQC1/qGCAgswggIHBgkq
# hkiG9w0BCQYxggH4MIIB9AIBATByMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRT
# eW1hbnRlYyBDb3Jwb3JhdGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFt
# cGluZyBTZXJ2aWNlcyBDQSAtIEcyAhAOz/Q4yP6/NW4E2GqYGxpQMAkGBSsOAwIa
# BQCgXTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0x
# NjEyMDYxMTIyMzVaMCMGCSqGSIb3DQEJBDEWBBTUN6nXsG9R+spiSDmvaNt5UwPd
# pjANBgkqhkiG9w0BAQEFAASCAQAgObhe66OtMfg2rHe+ewUh24XemMc62ikXxpba
# tV0hbqu/qsSjiCRLm0pT4gDWYaU5D3y+Hn2ynb89oGRpNYAqtTxP2d3N9N4MIFGG
# pA1j84sutJLIlRtlMiK3tWnSujEKfnUpI/RcYccVndnYzRFGfBmBOtapU6tYb9wC
# 8tQJPNt83vHtzBZjXaCgUytQbuBgmc8xlKuOHREpdT8uZ+sP4KyZknQBu6rjUGOR
# oLNSXixVIBGRNJZ0DBxORc9XpICKCt/x0iz4A3zv5PBSvKrPJnX4SIXYtp1keHil
# Ziqo+N45XCbP6iiwBxu1ftShrD63wOCERw11/sW/XUFd+v8D
# SIG # End signature block
