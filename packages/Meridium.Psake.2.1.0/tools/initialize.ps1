param($task = "default")

$currentPath = Resolve-Path .

Set-Location (Split-Path $MyInvocation.MyCommand.Path)

get-module psake | remove-module

import-module (Get-ChildItem "..\..\psake.*\tools\psake.psm1" | Select-Object -First 1)

. .\funclib.ps1

# Properties
$siteRoot = $currentPath
$toplevel = git rev-parse --show-toplevel
$websiteName = split-path $toplevel -leaf
$urlFriendly = urlify($websiteName)
$webAppPoolName = "$($urlFriendly)AppPool"
$websiteHostHeader = "$($urlFriendly).local"
$externalFilesPath = Join-Path "\\amanda\DataFiles\" $urlFriendly
$databaseName = "Dev-$($urlFriendly)-EPi"

exec { invoke-psake .\default.ps1 $task -properties @{ "siteRoot" = $siteRoot; "toplevel" = $toplevel; "websiteName" = $websiteName; "urlFriendly" = $urlFriendly; "webAppPoolName" = $webAppPoolName; "websiteHostHeader" = $websiteHostHeader; "externalFilesPath" = $externalFilesPath; "databaseName" = $databaseName; } }
