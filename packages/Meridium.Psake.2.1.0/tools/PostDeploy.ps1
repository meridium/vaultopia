. .\funclib.ps1
$urlFriendly = urlify($OctopusParameters["Octopus.Project.Name"])
Remove-Item (Join-Path $OctopusPackageDirectoryPath "*.psm1")
Remove-Item (Join-Path $OctopusPackageDirectoryPath "*.ps1")
Remove-Item (Join-Path $OctopusPackageDirectoryPath "*.UAT.config")
Remove-Item (Join-Path $OctopusPackageDirectoryPath "*.QA.config")

Import-Module WebAdministration
Start-WebSite $urlFriendly

if($runPostDeploymentTests -ne $null){
	import-module Conformance-Test
	$conformanceUris = Join-Path (Get-Location) "conformance-uris.txt"
	RunConformanceTests $urlFriendly $WCAG2Standard $YSlowThreshold $HipchatRoomId $OctopusParameters["Octopus.Web.ProjectLink"] $OctopusParameters["Octopus.Project.Name"] $OctopusParameters["Octopus.Environment.Name"] $OctopusParameters["Octopus.Web.ReleaseLink"] $OctopusParameters["Octopus.Release.Number"] $conformanceUris
}
Remove-Item (Join-Path $OctopusPackageDirectoryPath "*-uris.txt")
