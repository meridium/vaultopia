param($installPath, $toolsPath, $package, $project)

$projectDir = (Get-Item $project.FullName).Directory

Set-Location $projectDir

#Check if web.config has newsite key in web.config
$path = Join-Path $projectDir "web.config"
$xml = [xml](Get-Content $path)
$element = $xml.SelectSingleNode("configuration/appSettings/add[@key='newproject']")
if ($element){
    "Installing new project..." | Write-Host
    $installDate   = [system.datetime]::now.tostring('yyyy-MM-dd-HH-mm-ss')
    & $toolsPath\..\init.cmd initialize | Tee-Object "$($projectDir.Parent.FullName)\$($installDate)-Meridium.Psake.log" | Write-Host
	
	#Configure Prebuild event
	$solutionDir = New-Object System.Uri("$projectDir\..")
	$fullPathToInit =New-Object System.Uri("$toolsPath\..\init.cmd")

	$relativePath =  $solutionDir.MakeRelative($fullPathToInit).ToString().Replace("/","\")
	$preBuild=
@"
IF `$(ConfigurationName) == Debug goto :debug
goto :exit

:debug
IF NOT EXIST "`$(ProjectDir)modulesbin" goto :run
goto :exit

:run
cd ..
"`$(ProjectDir)..\$relativePath"

:exit
"@
	$project.Properties.Item("PreBuildEvent").Value = $preBuild

	. $toolsPath\..\funclib.ps1

	set-dependent-file $project "connectionStrings.config" "connectionStrings.QA.config"
	set-dependent-file $project "connectionStrings.config" "connectionStrings.UAT.config"

	set-dependent-file $project "EPiServerFramework.config" "EPiServerFramework.QA.config"
	set-dependent-file $project "EPiServerFramework.config" "EPiServerFramework.UAT.config"
}