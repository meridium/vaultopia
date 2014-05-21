# helper function that creates a new web client
Function Create-WebClient {
    # Add the necessary .NET assembly
    Add-Type -AssemblyName ('System.Net.Http, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')

    $webclient = New-Object System.Net.WebClient
    $webclient.Headers.Add('Content-Type','application/xml');
    $webclient.UseDefaultCredentials = 'true'
    $webclient.Credentials = New-Object System.Net.NetworkCredential($tcUser, $tcPasswd)

    return $webclient
}

# creates a new project in TC based on the template called EPiServer 7 CMS Template
# the new project name is defined in the properties section as the variable websiteName
Function Create-TC-Project($tcName) {
    # new project api payload
    $projectId=$tcName.Replace("-","_")
	$newProjectDescription = "<newProjectDescription name='$tcName' id='$projectId' copyAllAssociatedSettings='true'>
                                <parentProject locator='id:_Root'/>
                                <sourceProject locator='id:newProjectId'/>
                              </newProjectDescription>"

    # get the data from the xml document into a byte stream
    [byte[]]$byteArray = [System.Text.Encoding]::ASCII.GetBytes($newProjectDescription)

    # get a new web client
    $webclient = Create-WebClient

    # post the data and make a copy of the project
    $webclient.UploadData('http://teamcity.meridium.se/httpAuth/app/rest/projects', 'POST', $byteArray) | Out-Null
}

# adds a new GitHub VCS root pointing to the master branch
Function Add-VCS-Root($tcName, $identifier, $branchSpec) {

    # get the remote url from git
    $originUrl = git config --get remote.origin.url

	# if remote is https translate it to ssh
	if($originUrl.StartsWith("https://github.com")){
		$originUrl = "git@github.com:" + $originUrl.Replace("https://github.com/","")
	}

	$tcName=$tcName.Replace("-","_")
    # master branch identifier
    $root = "$tcName`_$identifier"
	
    # vcs root api payload
    $vcsRoot = "<vcs-root id='$root' name='$root' vcsName='jetbrains.git' projectLocator='$tcName'>
                  <properties>
                    <property name='agentCleanFilesPolicy' value='ALL_UNTRACKED'/>
                    <property name='agentCleanPolicy' value='ON_BRANCH_CHANGE'/>
                    <property name='authMethod' value='PRIVATE_KEY_DEFAULT'/>
                    <property name='branch' value='$identifier'/>
					<property name='teamcity:branchSpec' value='$branchSpec' />
                    <property name='ignoreKnownHosts' value='true'/>
                    <property name='submoduleCheckout' value='CHECKOUT'/>
                    <property name='url' value='$originUrl'/>
                    <property name='username' value=''/>
                    <property name='usernameStyle' value='USERID'/>
                  </properties>
                </vcs-root>"

    # get the data from the xml document into a byte stream
    [byte[]]$byteArray = [System.Text.Encoding]::ASCII.GetBytes($vcsRoot)

    # get a new web client
    $webclient = Create-WebClient

	[byte[]]$response = $webclient.UploadData('http://teamcity.meridium.se/httpAuth/app/rest/vcs-roots', 'POST', $byteArray)
	#Get the ID of the created vcs-root
    [xml]$xml = [System.Text.Encoding]::UTF8.GetString($response)
	$tmpRoot = select-xml "vcs-root" $xml
    return $tmpRoot.node.GetAttribute("id")
}

# associates the build called master to the correct VCS root
Function Associate-VCS-Root($tcName, $identifier, $vcsRootId) {
	
	$tcName=$tcName.Replace("-","_")
    
	$uri = "http://teamcity.meridium.se/httpAuth/app/rest/buildTypes/$tcName`_$identifier/vcs-root-entries"

    $vcsRoot = "<vcs-root-entry name='$tcName'>
                    <vcs-root id='$vcsRootId' />
                </vcs-root-entry>"

    # get the data from the xml document into a byte stream
    [byte[]]$byteArray = [System.Text.Encoding]::ASCII.GetBytes($vcsRoot)

    # get a new web client
    $webclient = Create-WebClient

    # post the data and create the new VCS root
    $webclient.UploadData($uri, "POST", $byteArray) | Out-Null
}

# adds a build step to the develop build, used for restoring nuget packages
Function Add-NuGet-Restore-Build-Step($tcName, $buildConfigName) {

	$tcName=$tcName.Replace("-","_")

	# get the top level of the repository
    $gitTopLevel = git rev-parse --show-toplevel

    # do a search for the solution file
    $slnFile = Get-ChildItem -Path $gitTopLevel -Filter *.sln -Recurse

    # resolve the relative path for the solution file
    Set-Location $gitTopLevel
    $slnPath = Resolve-Path -Relative $slnFile.FullName

    $uri = 'http://teamcity.meridium.se/httpAuth/app/rest/buildTypes/' + $tcName + '_'+$buildConfigName+'/steps'

    # build step api payload
    $buildStep = "<step name='Restore NuGet packages' type='jb.nuget.installer'>
                  <properties>
                    <property name='nuget.path' value='?NuGet.CommandLine.DEFAULT.nupkg'/>
                    <property name='nuget.sources' value='https://www.nuget.org/api/v2/&#xA;http://nuget.teamcity.meridium.se/nuget&#xA;http://nuget.episerver.com/feed/packages.svc/' />
                    <property name='nuget.updatePackages.mode' value='sln'/>
                    <property name='nugetCustomPath' value='?NuGet.CommandLine.DEFAULT.nupkg' />
                    <property name='nugetPathSelector' value='?NuGet.CommandLine.DEFAULT.nupkg'/>
                    <property name='sln.path' value='$slnPath'/>
					<property name='nuget.noCache' value='true'/>
                    <property name='teamcity.step.mode' value='default'/>
                  </properties>
                </step>"

    # get the data from the xml document into a byte stream
    [byte[]]$byteArray = [System.Text.Encoding]::ASCII.GetBytes($buildStep)

    # get a new web client
    $webclient = Create-WebClient

    # post the data and create the new build step
    $webclient.UploadData($uri, 'POST', $byteArray) | Out-Null
}

# adds a build step to the develop build, used for building the solution
# and runing octopack
Function Add-Build-Solution-Task($tcName, $buildConfigName) {

    $tcName=$tcName.Replace("-","_")

	$uri = 'http://teamcity.meridium.se/httpAuth/app/rest/buildTypes/' + $tcName + '_'+$buildConfigName+'/steps'

    # get the top level of the repository
    $gitTopLevel = git rev-parse --show-toplevel

    # do a search for the solution file
    $slnFile = Get-ChildItem -Path $gitTopLevel -Filter *.sln -Recurse

    # resolve the relative path for the solution file
    Set-Location $gitTopLevel
    $slnPath = Resolve-Path -Relative $slnFile.FullName
    
    # build step api payload
    $buildStep = "<step name='Build Solution' type='VS.Solution'>
                      <properties>
                        <property name='build-file-path' value='$slnPath'/>
                        <property name='msbuild.prop.Configuration' value='Release'/>
                        <property name='msbuild_version' value='4.5'/>
                        <property name='octopus_run_octopack' value='true'/>
                        <property name='octopus_octopack_package_version' value='0.0.0.%build.number%' />
                        <property name='run-platform' value='x86'/>
                        <property name='targets' value='Rebuild'/>
                        <property name='teamcity.step.mode' value='default'/>
                        <property name='toolsVersion' value='4.0'/>
                        <property name='vs.version' value='vs2012'/>
                      </properties>
                    </step>"

    # get the data from the xml document into a byte stream
    [byte[]]$byteArray = [System.Text.Encoding]::ASCII.GetBytes($buildStep)

    # get a new web client
    $webclient = Create-WebClient

    # post the data and create the new VCS root
    $webclient.UploadData($uri, "POST", $byteArray) | Out-Null

}

Function Add-Build-Step-NuGet-Pack($tcName, $buildConfigName) {

	$tcName=$tcName.Replace("-","_")

    # get the top level of the repository
    $gitTopLevel = git rev-parse --show-toplevel

    # do a search for the solution file
    $nuspecFile = Get-ChildItem -Path $gitTopLevel -Filter Deploy.nuspec -Recurse

    # resolve the relative path for the solution file
    Set-Location $gitTopLevel
    $nuspecPath = Resolve-Path -Relative $nuspecFile.FullName

    $uri = 'http://teamcity.meridium.se/httpAuth/app/rest/buildTypes/' + $tcName + '_'+$buildConfigName+'/steps'
    
    # build step api payload
    $buildStep = "<step name='NuGet Pack' type='jb.nuget.pack'>
                      <properties>
                        <property name='nuget.pack.as.artifact' value='true'/>
                        <property name='nuget.pack.output.clean' value='true'/>
                        <property name='nuget.pack.output.directory' value='%build.number%'/>
                        <property name='nuget.pack.project.dir' value='as_is'/>
                        <property name='nuget.pack.properties' value='Configuration=Release'/>
                        <property name='nuget.pack.specFile' value='$nuspecPath'/>
                        <property name='nuget.pack.version' value='%OctopusVersion%'/>
                        <property name='nuget.path' value='?NuGet.CommandLine.DEFAULT.nupkg'/>
                        <property name='nugetPathSelector' value='?NuGet.CommandLine.DEFAULT.nupkg'/>
                        <property name='teamcity.step.mode' value='default'/>
                      </properties>
                    </step>"

    # get the data from the xml document into a byte stream
    [byte[]]$byteArray = [System.Text.Encoding]::ASCII.GetBytes($buildStep)

    # get a new web client
    $webclient = Create-WebClient

    # post the data and create the new VCS root
    $webclient.UploadData($uri, "POST", $byteArray) | Out-Null

}

Function Add-Build-Step-Set-Version($tcName, $buildConfigName, $vcsRootId) {

	$tcName=$tcName.Replace("-","_")

	$uri = 'http://teamcity.meridium.se/httpAuth/app/rest/buildTypes/' + $tcName + '_'+$buildConfigName+'/steps'
	
	$code = "`$branch = &quot;%teamcity.build.vcs.branch.$vcsRootId%&quot;.substring(11)&#xA;`$hash = &quot;%build.vcs.number%&quot;.substring(0,7)&#xA;c:\apps\aver\aver.exe set . -scan -build &quot;%build.counter%.`$branch.`$hash&quot; -tcbuildno -verbose"
	$buildStep = "<step name='Set versions' type='jetbrains_powershell'>
                    <properties>
                        <property name='teamcity.step.mode' value='default'/>
                        <property name='jetbrains_powershell_bitness' value='x86'/>
                        <property name='jetbrains_powershell_script_mode' value='CODE'/>
                        <property name='jetbrains_powershell_script_code' value='$code'/>
                        <property name='jetbrains_powershell_execution' value='STDIN'/>
                        <property name='jetbrains_powershell_noprofile' value='true'/>
                    </properties>
                </step>"

    # get the data from the xml document into a byte stream
    [byte[]]$byteArray = [System.Text.Encoding]::ASCII.GetBytes($buildStep)

    # get a new web client
    $webclient = Create-WebClient

    # post the data and create the new step
    $webclient.UploadData($uri, "POST", $byteArray) | Out-Null
}

Function Create-Zip-Artifact($tcName, $buildConfigName, $siteRootName){

	$tcName=$tcName.Replace("-","_")

    $uri = 'http://teamcity.meridium.se/httpAuth/app/rest/buildTypes/' + $tcName + '_'+$buildConfigName+'/settings/artifactRules'
    $data = @"
$siteRootName/robots.txt => %env.TEAMCITY_PROJECT_NAME%-v%ShortVersion%.zip!/data/content
$siteRootName/FileSummary.config => %env.TEAMCITY_PROJECT_NAME%-v%ShortVersion%.zip!/data/content
$siteRootName/Global.asax => %env.TEAMCITY_PROJECT_NAME%-v%ShortVersion%.zip!/data/content
$siteRootName/bin => %env.TEAMCITY_PROJECT_NAME%-v%ShortVersion%.zip!/data/content/bin/
$siteRootName/Views => %env.TEAMCITY_PROJECT_NAME%-v%ShortVersion%.zip!/data/content/Views/
"@

    [byte[]]$byteArray = [System.Text.Encoding]::ASCII.GetBytes($data)

    # get a new web client
    $webclient = Create-WebClient

    # PUT the data and modify atrifact
    $webclient.UploadData($uri, "PUT", $byteArray) | Out-Null
}

Function Add-Build-Parameter($tcName, $buildConfigName, $parameterName, $parameterValue){
	$tcName=$tcName.Replace("-","_")

    $uri = 'http://teamcity.meridium.se/httpAuth/app/rest/buildTypes/' + $tcName + '_'+$buildConfigName+'/parameters/'+$parameterName
    [byte[]]$byteArray = [System.Text.Encoding]::ASCII.GetBytes($parameterValue)

    # get a new web client
    $webclient = Create-WebClient
    $webclient.Headers["Content-Type"]="text/plain"
    # PUT the data and add variable
    $webclient.UploadData($uri, "PUT", $byteArray) | Out-Null
}

Function Add-Build-Step-Prepare-Package  ($tcName, $buildConfigName) {

	$tcName=$tcName.Replace("-","_")

	$uri = 'http://teamcity.meridium.se/httpAuth/app/rest/buildTypes/' + $tcName + '_'+$buildConfigName+'/steps'
	
		$code =@"
# Get version from build number&#xA;
`$buildnumber = &quot;%build.number%&quot;&#xA;
`$version = `$buildnumber.substring(0, `$buildnumber.indexof(&quot;+&quot;))&#xA;
echo &quot;##teamcity[setParameter name=&apos;ShortVersion&apos; value=&apos;`$version&apos;]&quot;
"@

	$buildStep = "<step name='Prepare BuildPackage' type='jetbrains_powershell'>
                    <properties>
                        <property name='teamcity.step.mode' value='default'/>
                        <property name='jetbrains_powershell_bitness' value='x86'/>
                        <property name='jetbrains_powershell_script_mode' value='CODE'/>
                        <property name='jetbrains_powershell_script_code' value='$code'/>
                        <property name='jetbrains_powershell_execution' value='STDIN'/>
                        <property name='jetbrains_powershell_noprofile' value='true'/>
                    </properties>
                </step>"

    # get the data from the xml document into a byte stream
    [byte[]]$byteArray = [System.Text.Encoding]::ASCII.GetBytes($buildStep)

    # get a new web client
    $webclient = Create-WebClient

    # post the data and create the new step
    $webclient.UploadData($uri, "POST", $byteArray) | Out-Null
}

Function Add-Build-Step-Set-Octopus-Version  ($tcName, $buildConfigName) {

	$tcName=$tcName.Replace("-","_")

	$uri = 'http://teamcity.meridium.se/httpAuth/app/rest/buildTypes/' + $tcName + '_'+$buildConfigName+'/steps'
	
		$code =@"
`$versionNumber = &quot;%build.number%&quot; -replace &quot;(^[^+]+).*&quot;, &apos;`$1&apos;&#xA;
echo &quot;##teamcity[setParameter name=&apos;OctopusVersion&apos; value=&apos;`$versionNumber.%build.counter%&apos;]&quot;
"@

	$buildStep = "<step name='Set Octopus Version' type='jetbrains_powershell'>
                    <properties>
                        <property name='teamcity.step.mode' value='default'/>
                        <property name='jetbrains_powershell_bitness' value='x86'/>
                        <property name='jetbrains_powershell_script_mode' value='CODE'/>
                        <property name='jetbrains_powershell_script_code' value='$code'/>
                        <property name='jetbrains_powershell_execution' value='STDIN'/>
                        <property name='jetbrains_powershell_noprofile' value='true'/>
                    </properties>
                </step>"

    # get the data from the xml document into a byte stream
    [byte[]]$byteArray = [System.Text.Encoding]::ASCII.GetBytes($buildStep)

    # get a new web client
    $webclient = Create-WebClient

    # post the data and create the new step
    $webclient.UploadData($uri, "POST", $byteArray) | Out-Null
}