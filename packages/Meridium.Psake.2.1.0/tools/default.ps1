properties {
    # Common (don't change this if you don't know what you're doing)
    $siteRoot = $null
    $hostsPath = "$env:windir\System32\drivers\etc\hosts"
    $licensePath = "c:\epilicense\License.config"

    # Site
    $toplevel = $null
    $websiteName = $null
    $urlFriendly = $null

    $webAppPoolName = $null
    $websiteHostHeader = $null

    # EPiServer Framework
    $frameworkVersion = "7.5.394.2"

    # EPiServer CMS
    $epiVersion="7.5.394.2"
    $externalFilesPath = $null

    $epiUIPath = "/secure/"

    $vppTemplatePath= "\\amanda\Installation\EPiServer\VPP\7.5.394.2"
    
    # SQL server (don't change this if you don't know what you're doing)
    $sqlServerName = "amanda"
    $sqlServerPort = "1433"
    $databaseName = $null
    $databaseLoginName = "episerver"
    $databasePassword = "p@55W0rd!"
    $dbCreatorLoginName = "EPiServerDbCreator"
    $dbCreatorPassword = "gnu947!"

    # Team City credentials
    $tcUser = "admin"
    $tcPasswd = "gnu947!"
}

. .\funclib.ps1
. .\edit-xml.ps1

task default -depends devenv, create-symlink, setup-iis

task initialize -depends check-environment, setup-directory, copy-vpp, create-symlink, setup-config-transforms, setup-iis, devenv, install-database, setup-tc, setup-octopus

task qa -depends check-environment, load-episnapins, install-database { 
	Write-Host "Installing website with params: $urlFriendly, $webAppPoolName, $siteRoot, $websiteHostHeader, $externalFilesPath, $epiUIPath, $sqlServerName, $sqlServerPort, $databaseName, $databasePassword"
	install-website $urlFriendly $webAppPoolName $siteRoot $websiteHostHeader $externalFilesPath $epiUIPath $sqlServerName $sqlServerPort $databaseName $databasePassword
	create-default-user $sqlServerName $databaseName $dbCreatorLoginName $dbCreatorPassword
	cp $licensePath $siteRoot -force -ErrorAction SilentlyContinue
}

task uat -depends check-environment, load-episnapins, install-database {
    Write-Host "Installing website with params: $urlFriendly, $webAppPoolName, $siteRoot, $websiteHostHeader, $externalFilesPath, $epiUIPath, $sqlServerName, $sqlServerPort, $databaseName, $databasePassword"
    install-website $urlFriendly $webAppPoolName $siteRoot $websiteHostHeader $externalFilesPath $epiUIPath $sqlServerName $sqlServerPort $databaseName $databasePassword
	create-default-user $sqlServerName $databaseName $dbCreatorLoginName $dbCreatorPassword
	cp $licensePath $siteRoot -force -ErrorAction SilentlyContinue
}

task check-environment {
    if($PSVersionTable.CLRVersion.Major -lt 4) {
        write-warning "WTF! Not using CLR version 4, adding configuration file."
        
        $config = "<?xml version='1.0'?> 
<configuration> 
    <startup useLegacyV2RuntimeActivationPolicy='true'> 
        <supportedRuntime version='v4.0.30319'/> 
        <supportedRuntime version='v2.0.50727'/> 
    </startup> 
</configuration>"

        New-Item $pshome\powershell.exe.config -type file -force -value $config        
    }
}

task load-episnapins {
	Remove-PSSnapin EPiServer.Install.Common.1 -ErrorAction SilentlyContinue
	Add-PSSnapin EPiServer.Install.Common.1

	Remove-PSSnapin -Name EPiServer.Install.CMS.$epiVersion -ErrorAction SilentlyContinue
	Add-PSSnapin EPiServer.Install.CMS.$epiVersion
}

task setup-directory {
    # update gitignore
    update-gitignore $toplevel

    copy-item template.gitattributes (Join-Path $toplevel .gitattributes)

	copy-item template.conformanceuris (Join-Path $toplevel conformance-uris.txt)

	add-content $toplevel\conformance-uris.txt "[Startsida](http://$urlFriendly.qa.meridium.se)"


    # resolve the folder name for the web site
    $dirName = split-path $siteRoot -leaf

    # get the current location, i.e. the tools directory
    $current = Get-Location
    
    # push the current location so we can easily switch back after creating the nuspec
    Push-Location -Path $current -PassThru

    # set the location to the top level dir where we store the nuspec file
    Set-Location $toplevel -PassThru
    
    # resolve the tools path from the top level directory
    $toolsPath = (Resolve-Path -Relative $current).TrimStart(".\")

	#Generate Path to latest Psake package and include in deploy.nuspec
	$psakeFile = (Get-ChildItem "packages\psake.*\tools\psake.psm1" | Select-Object -First 1)
	$psakeFile = (Resolve-Path -Relative $psakeFile.FullName).TrimStart(".\")

    $nuspec = "<?xml version='1.0'?>
<package xmlns='http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd'>
    <metadata>
        <id>$websiteName</id>
        <version>0.0.1</version>
        <title>$(ToUpper $websiteName)</title>
        <summary></summary>
        <authors>Team Foxtrot</authors>
        <requireLicenseAcceptance>false</requireLicenseAcceptance>
        <description>$(ToUpper $websiteName)</description>
    </metadata>
    <files>
        <file src='$dirName\bin\*.*' target='bin' />
		<file src='$dirName\Views\**\*.*' target='Views' />
        <file src='$dirName\global.asax' target='' />
        <file src='$dirName\web.config' target='' />
        <file src='$dirName\episerverframework.config' target='' />
		<file src='$dirName\episerverframework.QA.config' target='' />
        <file src='$dirName\episerverframework.UAT.config' target='' />
		<file src='$dirName\episerver.config' target='' />
		<file src='$dirName\connectionStrings.config' target='' />
		<file src='$dirName\connectionStrings.QA.config' target='' />
        <file src='$dirName\connectionStrings.UAT.config' target='' />
		<file src='conformance-uris.txt' target='' />
		<file src='$psakeFile' target='' />
        <file src='$toolsPath\PreDeploy.ps1' target='' />
		<file src='$toolsPath\PostDeploy.ps1' target='' />
        <file src='$toolsPath\default.ps1' target='' />
        <file src='$toolsPath\funclib.ps1' target='' />
		<file src='$toolsPath\edit-xml.ps1' target='' />
    </files>
</package>"

    New-Item $toplevel\deploy.nuspec -type file -force -value $nuspec

	#Create Version file
	New-Item $toplevel\version.txt -type file -force -value "0.1.0"

    # switch back to the tools directory after saving the nuspec
    Pop-Location -PassThru

	#Fix global.asax.cs 
	$file = Join-Path $siteRoot "Global.asax.cs"
	if(Test-Path $file ){
			(gc $file ) -replace ": System.Web.HttpApplication", ": EPiServer.Global" | sc ($file)
	}

}

task create-symlink {
    # create symlink to external fileshare
    cmd /c "mklink /D $siteRoot\modulesbin $externalFilesPath\modulesbin"
}

task devenv -depends load-episnapins {
    # copy episerver runtime files to bin
    copy-epi-runtime-files $siteRoot
    
    # Modify hosts
    Add-Content $hostsPath "`n127.0.0.1`t$websiteHostHeader"

	# Copy license
    cmd /c "xcopy /Y $licensePath $siteRoot"
}

task setup-iis -depends load-episnapins {
    # setup site bindings for local address
    $bindings = "http:", $websiteHostHeader, ":80", ":default" -join ""

	# Create a new site
	New-EPiWebApp -SiteName $websiteName `
		-SitePath $siteRoot `
		-AppPoolName $webAppPoolName `
		-Bindings $bindings `
		-AppPoolManagedRuntimeVersion  "v4.0"
}

task install-database -depends load-episnapins {
    # EPi setup database
	Write-Host "installing database. Server: $sqlServerName, name: $databaseName"
    install-database $sqlServerName $databaseName $databasePassword $urlFriendly $epiUIPath
	create-default-user $sqlServerName $databaseName $dbCreatorLoginName $dbCreatorPassword | Out-Null
}

task copy-vpp  {
	#Copy TemplateVpp to SiteVPP
	Write-Host "Starting copy from $vppTemplatePath to $externalFilesPath"
	Invoke-Command -ComputerName "AMANDA" -ScriptBlock {param ($SourcePath,$InstallPath) 
                xcopy $SourcePath\*.* $InstallPath\*.* /E /I
            } -ArgumentList $vppTemplatePath, $externalFilesPath | Out-Null
}

task setup-config-transforms -depends setup-qa-transforms, setup-uat-transforms {
	edit-xml ( Join-Path $siteRoot "web.config") "configuration/appSettings/add[@key='newproject']" {
        param ($node)
        $node.ParentNode.RemoveChild($node)
    }

    edit-xml ( Join-Path $siteRoot "episerverframework.config") "episerver.framework/appData" {
        param ($node)
        $node.SetAttribute("basePath", $externalFilesPath)
    }

	#Change connstring
	edit-xml ( Join-Path $siteRoot "connectionStrings.config") "connectionStrings/add" {
        param ($node)
        $node.SetAttribute("connectionString", "Data Source=$sqlServerName;Database=$databaseName;User Id=dbUser$webSiteName;Password=$databasePassword;Network Library=DBMSSOCN;MultipleActiveResultSets=True")
    }

}

task setup-qa-transforms {
    edit-xml ( Join-Path $siteRoot "episerverframework.QA.config") "episerver.framework/appData" {
        param ($node)
        $node.SetAttribute("basePath", "E:\EPiServer\VPP\$urlFriendly")
    }

	#Change connstring
	edit-xml ( Join-Path $siteRoot "connectionStrings.QA.config") "connectionStrings/add" {
        param ($node)
        $node.SetAttribute("connectionString", "Data Source=$sqlServerName;Database=QA-$urlFriendly-EPi;User Id=dbUser$webSiteName;Password=$databasePassword;Network Library=DBMSSOCN;MultipleActiveResultSets=True")
    }

}

task setup-uat-transforms {
    edit-xml ( Join-Path $siteRoot "episerverframework.UAT.config") "episerver.framework/appData" {
        param ($node)
        $node.SetAttribute("basePath", "D:\EPiServer\VPP\$urlFriendly")
    }

	#Change connstring
	edit-xml ( Join-Path $siteRoot "connectionStrings.UAT.config") "connectionStrings/add" {
        param ($node)
        $node.SetAttribute("connectionString", "Data Source=.;Database=UAT-$urlFriendly-EPi;User Id=dbUser$webSiteName;Password=$databasePassword;Network Library=DBMSSOCN;MultipleActiveResultSets=True")
    }    
}

task setup-tc {
    . .\teamcity.ps1
	Push-Location -Path $current -PassThru

    Create-TC-Project $websiteName

    $masterId = Add-VCS-Root $websiteName 'master'
    $developId = Add-VCS-Root $websiteName 'develop' '+:refs/pull/(*/merge)'

    Associate-VCS-Root $websiteName 'master' $masterId
    Associate-VCS-Root $websiteName 'develop' $developId

    Add-Build-Step-Set-Version $websiteName 'master' $masterId
	Add-Build-Step-Set-Version $websiteName 'develop' $developId

	Add-Build-Step-Set-Octopus-Version $websiteName 'develop'
	
	Add-NuGet-Restore-Build-Step $websiteName 'master'
	Add-NuGet-Restore-Build-Step $websiteName 'develop'
    
	Add-Build-Solution-Task $websiteName 'master'
	Add-Build-Solution-Task $websiteName 'develop'

	Add-Build-Parameter $websiteName 'develop' 'OctopusVersion' ''
	Add-Build-Step-NuGet-Pack $websiteName 'develop'

	Add-Build-Step-Prepare-Package $websiteName 'master'
	Add-Build-Parameter $websiteName 'master' 'ShortVersion' 'v1.0.0'

	Create-Zip-Artifact $websiteName 'master' (split-path $siteRoot -leaf)

	Pop-Location -PassThru
}

task setup-octopus {
	
	. .\octopus.ps1

	$projectId = Create-New-Octopus-Project $websiteName

	$actionId = Add-Octopus-DeploymentProcess $projectId $websiteName

	Setup-Octopus-Variables $projectId $websiteName $actionId
}