param($task = "qa", $siteRoot = $null, $webSiteName = $null)

. .\funclib.ps1

if ($env:Processor_Architecture -ne "x86") {

	$urlFriendly = urlify($OctopusProjectName)
	Import-Module WebAdministration
	if (Test-Path "IIS:\Sites\$urlFriendly" ) {
		Stop-WebSite $urlFriendly
		return
	}
	else{
		write-warning "switching to 32x and continuing script."
		&"$env:windir\syswow64\windowspowershell\v1.0\powershell.exe" `
		-noprofile -file $myinvocation.Mycommand.path -siteRoot $OctopusPackageDirectoryPath -webSiteName $OctopusProjectName -executionpolicy bypass
		exit
	 }
}

$currentPath = Resolve-Path .

get-module psake | remove-module

import-module (Join-Path $currentPath "psake.psm1")

Write-Host "Invoke Psake with siteRoot: $siteRoot and webSiteName: $webSiteName"
# Properties
$toplevel = $null
$urlFriendly = urlify($websiteName)
$webAppPoolName = "$($urlFriendly)AppPool"
$externalFilesPath = "E:\EPiServer\VPP\"
$websiteHostHeader = "$($urlFriendly).qa.meridium.se"
$databaseName = "QA-$($urlFriendly)-EPi"
$sqlServerName = "amanda"
$dbCreatorLoginName = "EPiServerDbCreator"
$dbCreatorPassword = "gnu947!"
$isUATEnvironment = $env:computername.CompareTo("ERICA")

if ($isUATEnvironment -eq 0) {
    $task = "uat"
    $websiteHostHeader = "$($urlFriendly).uat.meridium.se"
    $databaseName = "UAT-$($urlFriendly)-EPi"
    $sqlServerName = "."
    $dbCreatorLoginName = "sa"
    $dbCreatorPassword = "Be3sfG-9"
	$externalFilesPath = "D:\EPiServer\VPP\"
}
$externalFilesPath = Join-Path $externalFilesPath $urlFriendly

exec { invoke-psake .\default.ps1 $task -properties @{ siteRoot = $siteRoot; "websiteName" = $websiteName; "urlFriendly" = $urlFriendly; "webAppPoolName" = $webAppPoolName; "websiteHostHeader" = $websiteHostHeader; "externalFilesPath" = $externalFilesPath; "databaseName" = $databaseName; "sqlServerName" = $sqlServerName; "dbCreatorLoginName" = $dbCreatorLoginName; "dbCreatorPassword" = $dbCreatorPassword } }
