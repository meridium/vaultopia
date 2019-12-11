param($installPath, $toolsPath, $package, $project)

$libPath = join-path $installPath "lib\net461"

#Updates the supplied assemblyConfigs for the supplied file
Function UpdateBindingRedirect([System.IO.FileInfo] $file, [System.Xml.XmlElement] $assemblyBinding, [System.Xml.XmlElement[]] $assemblyConfigs, [bool] $addMissing) {
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
		if($addMissing -eq $false) {
			return $false
		}
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


$projectFile = Get-Item $project.FullName
$configPath = join-path $projectFile.Directory.FullName "web.config"

#If web.config file is missing, check if we have an app.config
if(!(test-path $configPath)) {
    $configPath = join-path $projectFile.Directory.FullName "app.config"
}

#if we have a config file, update it's assembly references (if any)
if((test-path $configPath)) {

    $config = New-Object xml
    $config.Load($configPath)
    $assemblyBinding = $config.configuration.runtime.assemblyBinding
    $assemblyConfigs = $assemblyBinding.dependentAssembly

    $configModified=$false
    foreach($item in (get-childItem "$libPath\*.dll")) {
        if(UpdateBindingRedirect $item $assemblyBinding $assemblyConfigs $false) {
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
# MIIW3AYJKoZIhvcNAQcCoIIWzTCCFskCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUVgT2kW44npBMIpZVWIGDKDpl
# jDKgghIsMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
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
# vz4iaGNTmr1pdKzFHTx/kuDDvBzYBHUwggT3MIID36ADAgECAgxbaqMrr7vXC1sL
# EDswDQYJKoZIhvcNAQELBQAwWjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2Jh
# bFNpZ24gbnYtc2ExMDAuBgNVBAMTJ0dsb2JhbFNpZ24gQ29kZVNpZ25pbmcgQ0Eg
# LSBTSEEyNTYgLSBHMzAeFw0xNzA5MTExMTA2MDRaFw0xODEwMjIwOTQzNDNaMHEx
# CzAJBgNVBAYTAlNFMQ8wDQYDVQQHEwZLQUxNQVIxFTATBgNVBAoTDE1lcml3b3Jr
# cyBBQjEVMBMGA1UEAxMMTWVyaXdvcmtzIEFCMSMwIQYJKoZIhvcNAQkBFhRzdXBw
# b3J0QG1lcml3b3Jrcy5zZTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
# ALSaUFYW4cAs7x/wNck3Row8adqsKde6EV9vhMRtyUiafrPiFjtNs7wA0wd3UclJ
# UpCQpQ8t2yqC9y0MTzfmPmUjdrJS9KyBiFVstJiF+D1faaohRtqC/v/9Sa6VScyE
# jmxxi1XuKxVHeruvcuAiJfgzsSK5vQU8I9eJL8YrnMoLE73+YBRQDIAsJOjSvsmF
# KOSxQ7DACgR211jGIWX9hbFZus9dR90p3Drh5B8CR4LEK+r0GIBh71Y8QOP5TgWq
# eRe8NKJHte8ZIUk2FHZkI3LcDeVlcdV3tQExISJMObU1A4g0+vzd4q76txCiR5Di
# 0LMa+HEXMfdXfF7da98YGXcCAwEAAaOCAaQwggGgMA4GA1UdDwEB/wQEAwIHgDCB
# lAYIKwYBBQUHAQEEgYcwgYQwSAYIKwYBBQUHMAKGPGh0dHA6Ly9zZWN1cmUuZ2xv
# YmFsc2lnbi5jb20vY2FjZXJ0L2dzY29kZXNpZ25zaGEyZzNvY3NwLmNydDA4Bggr
# BgEFBQcwAYYsaHR0cDovL29jc3AyLmdsb2JhbHNpZ24uY29tL2dzY29kZXNpZ25z
# aGEyZzMwVgYDVR0gBE8wTTBBBgkrBgEEAaAyATIwNDAyBggrBgEFBQcCARYmaHR0
# cHM6Ly93d3cuZ2xvYmFsc2lnbi5jb20vcmVwb3NpdG9yeS8wCAYGZ4EMAQQBMAkG
# A1UdEwQCMAAwPwYDVR0fBDgwNjA0oDKgMIYuaHR0cDovL2NybC5nbG9iYWxzaWdu
# LmNvbS9nc2NvZGVzaWduc2hhMmczLmNybDATBgNVHSUEDDAKBggrBgEFBQcDAzAd
# BgNVHQ4EFgQUU61MTqdbsKaxdvWuvDAXiwYna20wHwYDVR0jBBgwFoAUDzrnrJSR
# dC2WAnODrZwuST8ZqlQwDQYJKoZIhvcNAQELBQADggEBAEeroCejpi9v+dCzwcZt
# 3qrKcC9yuLV2g42tvK6EYqipK+rAHJ397qJMgW6sX36otvrmEx4ke08sZpR7azgF
# 5IJTQlu6Iz4QYziahJrSEZeQ6WG3+rwHU50FrIUng3EdWONdiVlMcMi4Ddq79FCE
# 4JB30Bye6x2lh8DpXyQCFyGqkmS3jnHdlrTBEmCqwDjyB6DVybYfHqLf5K5T6d9z
# KSIBer151iQ+1aJq0dqEuk10uc3JC7992BMwDRPg/prQRTX9ZSwWUlEdI66J+2sl
# ZJ/KdO2auuW2TaEAgfuDuzShgHWrHESUr1Oc161ritnKVVxA2U4NRzd4GTKYAXx2
# KQcxggQaMIIEFgIBATBqMFoxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxT
# aWduIG52LXNhMTAwLgYDVQQDEydHbG9iYWxTaWduIENvZGVTaWduaW5nIENBIC0g
# U0hBMjU2IC0gRzMCDFtqoyuvu9cLWwsQOzAJBgUrDgMCGgUAoHgwGAYKKwYBBAGC
# NwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQU8jgawpqd
# UF3PnpQsQQV60GU+pjAwDQYJKoZIhvcNAQEBBQAEggEAh3bWrJ3oA209nzXwHGWT
# XhoD07GuPofJDqN5huH98T1X9anUVEykpQ9CBiHkNoY6oNauAXyVReK1sgNxpZzN
# e6PxcMR/cqoHwef4AhkyW8Pq1qeVqG8yIq0jTo8ArlL5k7Kg3GdKJescbZ+9s/M/
# cinxxnEE5SAnAQz8pbk9vIzoWVac8jc4wiVerjlZnDHx6M+VFg8+y/YFNb01yr/g
# wfRzx6DKO9CD7E+4J6TSQyssprPJhBIXkcsPDwJ3t8FhtgEqcnzA4trSm29ZIc6w
# pIuNRJSRfZ6ItKi7x3d1kA8XygBUPWBj/hA80jPcxE3izPROqgIXIZDaILKJMtZQ
# z6GCAgswggIHBgkqhkiG9w0BCQYxggH4MIIB9AIBATByMF4xCzAJBgNVBAYTAlVT
# MR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3JhdGlvbjEwMC4GA1UEAxMnU3ltYW50
# ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBDQSAtIEcyAhAOz/Q4yP6/NW4E2GqY
# GxpQMAkGBSsOAwIaBQCgXTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqG
# SIb3DQEJBTEPFw0xODA0MjUwOTIyNTRaMCMGCSqGSIb3DQEJBDEWBBSPgNxlOeHQ
# vzeQeKlV5ypu1AxM1jANBgkqhkiG9w0BAQEFAASCAQCOZx0kp1kxbOovHnSZK4Cf
# UZajLmFDh73wZrx/xAyUMlsqsMz3tQPUwPk7ojTtio5Y6/Tdn238E+ouoFM4wcOc
# MGZgsoVvzxBnFVmqgOyXvDTGSIiMb1sNizOffhe3+tpSRktI+4L/3B/JCJu272VY
# rsxKirsRywcOMLYCmI0xRToyrHUtnY62pbFEWaTgmNsh0BGd0y82xA9AwxNdODIt
# zZ7raIIrzDAhhrxDK/RuZZdgeh4oL5jGviuvmewXtkVPDzjs0aSq8np8hobhsyQd
# KiuBkdq38A+oHbiJT2yvrh594463xPfPSnGQX+a2pA6rtjokwNxLSCwS5vibK+Nm
# SIG # End signature block
