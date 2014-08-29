Function LogWrite
{
   Param ([string]$logstring)

   Write-Host $logstring
}
trap [Exception]
{
	LogWrite ""
	LogWrite "An unhandled error has occured:"
	LogWrite $_.Exception
	LogWrite "When executing"
	LogWrite $_.InvocationInfo.PositionMessage
	LogWrite ""	$inTransaction = Get-EPiIsBulkInstalling

	$inTransaction = Get-EPiIsBulkInstalling

	if($inTransaction -eq $true)
	{
		#Rollback-EPiBulkInstall
	}	
	
	break
}

function ToUpper( $websiteName ) {
    return $websiteName.substring(0,1).toupper()+$websiteName.substring(1) 
}

function update-gitignore( $toplevel ) {
	$current = Get-Location
	$template = get-content (Join-Path $current template.gitignore)
	foreach ($l in $template) {
		add-content $toplevel\.gitignore $l
	}
}

function copy-epi-runtime-files( $siteRoot ) {
    $cmsProductInfo = Get-EPiProductInformation -ProductName "CMS" -ProductVersion $epiVersion
    if (!$cmsProductInfo.IsInstalled)
    {
	    throw(New-Object ApplicationException($resources.GetString("ErrorInstallationDirectoryNotFound")))
    }
    $frameworkProductInfo = Get-EPiProductInformation -ProductName "EPiServerFramework" -ProductVersion $FrameworkVersion
    if (!$frameworkProductInfo.IsInstalled)
    {
	    throw(New-Object ApplicationException($resources.GetString("ErrorInstallationDirectoryNotFound")))
    }

    Copy-Item (Join-Path $cmsProductInfo.InstallationPath "bin\*") (Join-Path $siteRoot "bin")
    Copy-Item (Join-Path $frameworkProductInfo.InstallationPath "bin\*") (Join-Path $siteRoot "bin")
}

function install-database ( $sqlServerName, $databaseName, $databasePassword, $websiteName, $uiPath ) {

	$wizard = New-EPiCMSWizard "NewSqlServerDatabaseWizard"
	$resources = $wizard.Resources

	$wizard.Database.DatabaseServerName = $sqlServerName
	$wizard.Database.DatabaseName = $databaseName
	$wizard.Database.ProductDatabaseLoginName = "dbUser$websiteName"
    $wizard.Database.ProductDatabaseLoginPassword = $databasePassword
	$wizard.Database.InstallerUseWindowsAuthentication = $false
	$wizard.Database.InstallerDatabaseLoginName = $dbCreatorLoginName
	$wizard.Database.InstallerDatabaseLoginPassword = $dbCreatorPassword
	
	$wizardNotProvided = $true

    $cmsProductInfo = Get-EPiProductInformation -ProductName "CMS" -ProductVersion $epiVersion
    if (!$cmsProductInfo.IsInstalled)
    {
	    throw(New-Object ApplicationException($resources.GetString("ErrorInstallationDirectoryNotFound")))
    }

    $frameworkProductInfo = Get-EPiProductInformation -ProductName "EPiServerFramework" -ProductVersion $FrameworkVersion
    if (!$frameworkProductInfo.IsInstalled)
    {
	    throw(New-Object ApplicationException($resources.GetString("ErrorInstallationDirectoryNotFound")))
    }

    # Start a bulk install so that the operations below are atomic
	$inTransaction = Get-EPiIsBulkInstalling

	if($inTransaction -eq $false)
	{
		Begin-EPiBulkInstall
	}
		
	# create a new database for this installation, passing String.Empty to the LoginName and LoginPassword parameters will force use of Windows authentication
	New-EPiSqlSvrDB `
	-SqlServerName $wizard.Database.DatabaseServerName `
	-SqlServerPort $wizard.Database.DatabaseServerPort `
	-DatabaseName $wizard.Database.DatabaseName `
	-LoginName $wizard.Database.InstallerDatabaseLoginName `
	-LoginPassword $wizard.Database.InstallerDatabaseLoginPassword `
	-InstallAspNetSchema `
	-InstallWFSchema

	# Install the EPiServer Framework Schema (using the shipped Powershell script for this)
	$modulePath = Join-Path $frameworkProductInfo.InstallationPath "Install\System Scripts\Install Database (SqlServer).ps1"
	& $modulePath -properties $wizard -AvoidDbTransaction

	# Install the CMS Schema
	Execute-EPiSqlSvrScript `
	-SqlServerName $wizard.Database.DatabaseServerName `
	-SqlServerPort $wizard.Database.DatabaseServerPort `
	-DatabaseName $wizard.Database.DatabaseName `
	-LoginName $wizard.Database.InstallerDatabaseLoginName `
	-LoginPassword $wizard.Database.InstallerDatabaseLoginPassword `
	-ScriptPath (Join-Path $cmsProductInfo.InstallationPath "Database\MSSQL\EPiServerRelease75.sql") `
	-EPiServerScript `
	-AvoidDbTransaction

	if ($wizard.Database.UserExistsInDatabase -eq $false)
	{	
		# add a new user to the database
		Add-EPiSqlSvrUser -SqlServerName $wizard.Database.DatabaseServerName -SqlServerPort $wizard.Database.DatabaseServerPort -DatabaseName $wizard.Database.DatabaseName -LoginName $wizard.Database.InstallerDatabaseLoginName -LoginPassword $wizard.Database.InstallerDatabaseLoginPassword -UserName $wizard.Database.ProductDatabaseLoginName -UserPassword $wizard.Database.ProductDatabaseLoginPassword										
	}
	
	if (![System.String]::IsNullOrEmpty($uiPath)) 
	{
		# Finalize the built in pagetypes paths; Avoiding DB transaction since create database drops the db on rollback 
		Set-EPiBuiltInPageTypePaths -SqlServerName $wizard.Database.DatabaseServerName `
			-SqlServerPort $wizard.Database.DatabaseServerPort `
			-DatabaseName $wizard.Database.DatabaseName `
			-LoginName $wizard.Database.InstallerDatabaseLoginName `
			-LoginPassword $wizard.Database.InstallerDatabaseLoginPassword `
			-UiPath "~$uiPath" `
			-AvoidDbTransaction
	}

    if($inTransaction -eq $false)
	{
		Commit-EPiBulkInstall
	}

}

function install-website ( $websiteName, $webAppPoolName, $siteRoot, $websiteHostHeader, $externalFilesPath, $epiUIPath, $sqlServerName, $sqlServerPort, $databaseName, $databasePassword ) {
	$wizard = New-EPiCMSWizard "NewSiteWizard"

	$wizard.Site.SiteName = $websiteName
	$wizard.Site.AppPoolName = $webAppPoolName
	$wizard.Site.SitePath = $siteRoot
	$wizard.Site.SiteBindings = "http:", $websiteHostHeader, ":80", ":default" -join ""
	$wizard.Site.ExternalFilesPath = $externalFilesPath
	
    $wizard.EPiUIPath = $epiUIPath

	$wizardNotProvided = $true

    $resources = $wizard.Resources

    # Get the version location path of EPiServer in order to find resources
    $cmsProductInfo = Get-EPiProductInformation -ProductName "CMS" -ProductVersion $epiVersion
    if (!$cmsProductInfo.IsInstalled)
    {
	    throw(New-Object ApplicationException($resources.GetString("ErrorInstallationDirectoryNotFound")))
    }

    $frameworkProductInfo = Get-EPiProductInformation -ProductName "EPiServerFramework" -ProductVersion $FrameworkVersion
    if (!$frameworkProductInfo.IsInstalled)
    {
	    throw(New-Object ApplicationException("EPiServerFramework installation directory was not found"))
    }
    $epiVersionPath = $cmsProductInfo.InstallationPath

    $proceedWithInstall = $true

	# Target folder and file variables
	$sourceBinFolder = Join-Path $epiVersionPath "bin"
	$sourceApplicationFolder = Join-Path $epiVersionPath "application"

	$targetBinFolder = Join-Path $wizard.Site.SitePath "bin"
	$targetWebConfigPath = Join-Path $wizard.Site.SitePath "web.config"
	$targetConnectionStringsConfigPath = Join-Path $wizard.Site.SitePath "connectionStrings.config"
	
	# UI Path
	$epiCmsUIPath = $wizard.EPiUIPath + "CMS/"
	$epiCMSUiUrl = $wizard.EPiUIUrl + "CMS/"
        
    $webServer = Get-EPiWebServer

	# Start a bulk install so that the operations below are atomic
	$inTransaction = Get-EPiIsBulkInstalling

	if($inTransaction -eq $false)
	{
		Begin-EPiBulkInstall
	}
	# Create the destination directory
	New-EPiDirectory -DirectoryPath $wizard.Site.SitePath
	New-EPiDirectory -DirectoryPath $targetBinFolder
	New-EPiDirectory -DirectoryPath $wizard.Site.ExternalFilesPath	

    # Calculate source and target folder paths for the subfolders of the source application folder.
	$sourceAppBrowsersFolder = Join-Path $sourceApplicationFolder "App_Browsers"
	$sourceAppThemesFolder = Join-Path $sourceApplicationFolder "App_Themes\Default"
	$sourceUiFolder = Join-Path $sourceApplicationFolder "UI\CMS"
	$sourceUtilFolder = Join-Path $sourceApplicationFolder "util"
	$sourceWebServiceFolder = Join-Path $sourceApplicationFolder "webservices"
	
	# Copy files to the destination directory
	Copy-EPiFiles -SourceDirectoryPath $sourceApplicationFolder -DestinationDirectoryPath $wizard.Site.SitePath
	Copy-EPiFiles -SourceDirectoryPath $sourceBinFolder -DestinationDirectoryPath $targetBinFolder

    # Set up access rights for the destination folders
	# Get the name of the user configured for anonymous access and the worker process accounts
	$anonymousUserName = $webServer.AnonymousUserAccount($wizard.Site.SiteName)
	$workerProcessGroups = $webServer.WorkerProcessAccounts($wizard.Site.AppPoolName)

	if (![string]::IsNullOrEmpty($anonymousUserName))
	{
		Set-EPiAccess -FileSystemPath $wizard.Site.SitePath -Grant "[OI][CI]R" -Identity $anonymousUserName
	}

	foreach($accountName in $workerProcessGroups)
	{
		Set-EPiAccess -FileSystemPath $wizard.Site.SitePath -Grant "[OI][CI]R" -Identity $accountName
		
		# Set permission to modify web.config, episerver.config, episerverframework.config and connectionStrings.config and create temp files in Site Path
		Set-EPiAccess -FileSystemPath $wizard.Site.SitePath -Grant "M" -Identity $accountName
		Set-EPiAccess -FileSystemPath (Join-Path $wizard.Site.SitePath "episerver.config") -Grant "M" -Identity $accountName
		Set-EPiAccess -FileSystemPath $targetWebConfigPath -Grant "M" -Identity $accountName
		Set-EPiAccess -FileSystemPath $targetConnectionStringsConfigPath -Grant "M" -Identity $accountName

		# Set up access rights for the VPP folders
		Set-EPiAccess -FileSystemPath $wizard.Site.ExternalFilesPath -Grant "[OI][CI]M" -Identity $accountName
	}

	$appRelativeCmsUIPath = "~" + $epiCmsUIPath
	# Set up the correct URI:s in web.config
	Set-EPiXmlAttribute -TargetFilePath $targetWebConfigPath -ElementXPath "/configuration/epi:episerver/epi:applicationSettings" -AttributeName "uiUrl" -AttributeValue $epiCMSUiUrl
	Set-EPiXmlAttribute -TargetFilePath $targetWebConfigPath -ElementXPath "/configuration/epi:episerver/epi:applicationSettings" -AttributeName "utilUrl" -AttributeValue "~/util/"

    # Install the EPiServer Framework files and config
	$modulePath = Join-Path $frameworkProductInfo.InstallationPath "Install\System Scripts\Install Site (No database).ps1"
	& $modulePath -properties $wizard
	
	# Update web.config with defaults for EPiServer Framework
	$frameworkModificationFile = Join-Path $epiVersionPath "Install\System Scripts\EPiServerFramework.CmsDefaults.xmlupdate"
	$frameworkUiLocationPath = $wizard.EPiUIPath.Trim('/')
	$frameworkPhysicalPath = Join-Path $frameworkProductInfo.InstallationPath "Application\UI"
	$frameworkGeoLiteDbPath = Join-Path $frameworkProductInfo.InstallationPath "Geolocation"

	$destinationDirectoryPath = Join-Path $wizard.Site.ExternalFilesPath "Geolocation"
	New-EPiDirectory -DirectoryPath $destinationDirectoryPath
	Copy-EPiFiles `
		-SourceDirectoryPath $frameworkGeoLiteDbPath `
		-DestinationDirectoryPath $destinationDirectoryPath

    $frameworkGeoLiteLocalPath = "[appDataPath]\Geolocation\GeoLiteCity.dat"
	$cmsPhysicalPath = Join-Path $sourceApplicationFolder "UI\EPiServer\CMS"
	Update-EPiXmlFile -TargetFilePath $targetWebConfigPath `
					  -ModificationFilePath $frameworkModificationFile `
					  -Replaces "{uilocationpath}=$frameworkUiLocationPath;{frameworkphysicalpath}=$frameworkPhysicalPath;{cmsphysicalpath}=$cmsPhysicalPath;{geoLiteDbPath}=$frameworkGeoLiteLocalPath"
	
	
	# Update the siteid with that chosen in the wizard
	$siteId = $wizard.Site.SiteName.Replace(' ', '_') # we don't want spaces in the siteId
	
	if ($wizard.Site.ApplicationName)
	{
		# Non null application name so append it
		$siteId += "_" + $wizard.Site.ApplicationName.Replace(' ', '_')
	}	
	
	Set-EPiXmlAttribute -TargetFilePath $targetWebConfigPath -ElementXPath "/configuration/epi:episerver/epi:sites/epi:site[1]" -AttributeName "siteId" -AttributeValue $siteId

    #Meridium Set basepath to configured externalPath
	Set-EPiXmlAttribute -TargetFilePath $targetWebConfigPath -ElementXPath "/configuration/episerver.framework/appData" -AttributeName "basePath" -AttributeValue $externalFilesPath

	
	# Update location paths
	Set-EPiXmlAttribute -TargetFilePath $targetWebConfigPath -ElementXPath "//location[@path='EPiServer']" -AttributeName "path" `
						-AttributeValue $wizard.EPiUIPath.Trim('/')
	Set-EPiXmlAttribute -TargetFilePath $targetWebConfigPath -ElementXPath "//location[@path='EPiServer/CMS/admin']" -AttributeName "path" `
						-AttributeValue ($epiCmsUIPath.Trim('/') + "/admin")
	
	# Add Assembly Redirects to web.config
	$versionRange = "5.2.375.0-7.65535.65535.65535"
	
	ForEach ($file in Get-ChildItem -Path $sourceBinFolder\*.dll)
	{
		echo "Assembly redirect for ${file}"
		Add-EPiAssemblyRedirect -TargetFilePath $targetWebConfigPath -SourceAssemblyPath $file.FullName
	}

	$fxSnapInName = "EPiServer.Install.Packaging." + $frameworkProductInfo.Version

	$snapIn = Get-PSSnapin -Name $fxSnapInName -ErrorAction SilentlyContinue
	if ($snapIn -eq $null)
	{
	    Add-PSSnapin $fxSnapInName
	}

	$apiRoot = Join-Path $frameworkProductInfo.InstallationPath "Install\Tools"

	$packageFiles = Get-ChildItem (Join-Path $epiVersionPath "packages") `
		| where { ($_.extension -eq ".nupkg") -and ($_.Name.StartsWith("CMS.") -or $_.Name.StartsWith("EPiServer.Suite.")) } | % { $_.FullName }
		
	if ($packageFiles -ne $null)
	{
		echo "Installing Add-Ons:"
		Add-EPiAddOn -ApplicationPath $wizard.Site.SitePath -ApiPath $apiRoot -Files $packageFiles | %{$_.Package} | Format-List Id, Title, Version | Out-Default
	}

	LogWrite "Create Site"
	# Create a new site		
	New-EPiWebApp -SiteName $wizard.Site.SiteName `
		-ApplicationName $wizard.Site.ApplicationName `
		-SitePath $wizard.Site.SitePath `
		-AppPoolName $wizard.Site.AppPoolName `
		-Bindings $wizard.Site.SiteBindings `
		-AppPoolManagedRuntimeVersion  "v4.0"
	
	# If this is an express install we need to store the name of the site we created 
	if ($registerSite -eq $true)
	{
		Set-EPiRegistryValue -KeyName "Software\EPiServer\CMS\$epiVersion" -ValueName "InstallerSiteCreated" -Value $wizard.Site.SiteName
	}


	LogWrite("PopulateDB connections")
	# Populating database connection properties 
	$connectionStringFactory = New-Object EPiServer.Install.SqlServer.SqlServerConnectionFactory
	$connectionStringFactory.ServerName = $sqlServerName
	$connectionStringFactory.ServerPort = $sqlServerPort
	$connectionStringFactory.DatabaseName = $databaseName 
	$connectionStringFactory.SQLServerLoginName =  "dbUser$websiteName" 
	$connectionStringFactory.SQLServerLoginPassword = $databasePassword
	$connectionStringFactory.UseWindowsAuthentication = $false
	$connectionStringFactory.MultipleActiveResultSets = $true

	# Set the connection string in connectionStrings.config	
	$targetConnectionStringsConfigPath = [System.IO.Path]::Combine($wizard.Site.SitePath, "connectionStrings.config")
	Set-EPiXmlAttribute -TargetFilePath $targetConnectionStringsConfigPath -ElementXPath "/connectionStrings/add[@name='EPiServerDB']" -AttributeName "connectionString" -AttributeValue $connectionStringFactory.ConnectionString	

    if($inTransaction -eq $false)
	{
		Commit-EPiBulkInstall
	}    
}
function urlify( $text ) {
    $bytes = [System.Text.Encoding]::GetEncoding("Cyrillic").GetBytes($text)
    $result = [System.Text.Encoding]::ASCII.GetString($bytes).ToLower()

    $rx = [System.Text.RegularExpressions.Regex]
    $result = $rx::Replace($result, "[^a-z0-9\s-]", "")
    $result = $rx::Replace($result, "\s+", " ").Trim(); 
    $result = $rx::Replace($result, "\s", "-");
    $result
}

function set-dependent-file($project, $parentFileName, $subFileName){
	# Selections of items in the project are done with Where-Object rather than
	# direct access into the ProjectItems collection because if the object is
	# moved or doesn't exist then Where-Object will give us a null response rather
	# than the error that DTE will give us.

	# The Service.cs will show with a sub-item if it's already got the designer
	# file set. In the package upgrade scenario, you don't want to re-set all
	# this, so skip it if it's set.
	$parentItem = $project.ProjectItems | Where-Object { $_.Properties.Item("Filename").Value -eq $parentFileName }

	if($parentItem -eq $null)
	{
		# Upgrade scenario - user has moved/removed the $parentFileName
		return
	}

	$subItem = $project.ProjectItems | Where-Object { $_.Properties.Item("Filename").Value -eq $subFileName }

	if($subItem -eq $null)
	{
		# Upgrade scenario - user has moved/removed the $subFileName
		return
	}

	# Here's where you set the sub-file to be a dependent file of
	# the parent file.
	$parentItem.ProjectItems.AddFromFile($subItem.Properties.Item("FullPath").Value)
}
function create-default-user{
param($sqlserver, $dbName, $dbUser, $dbPassword)
    $conn = new-Object System.Data.SqlClient.SqlConnection("Data Source=$sqlserver;Database=$dbName;User Id=$dbUser;Password=$dbPassword;Network Library=DBMSSOCN;MultipleActiveResultSets=True")
    try {
	   $conn.Open() | out-null
       create-user $conn
       add-role $conn "WebAdmins"
       add-role $conn "WebEditors"
       add-user-to-roles $conn "WebAdmins,WebEditors" 
	   add-permission-for-role $conn "WebAdmins" 1
	   add-permission-for-role $conn "WebAdmins" 2
	   add-permission-for-role $conn "WebEditors" 1
	   add-permission-for-role $conn "WebEditors" 2    
    }
    finally{
        $conn.Close();
    }
}

function add-param{ 
    param($cmd, $paramName, $direction, $type, $value) 
    $cmd.Parameters.Add("$paramName",$type) | out-Null
	$cmd.Parameters["$paramName"].Direction = $direction
	$cmd.Parameters["$paramName"].Value = $value
}

function create-user { param($conn)
	$cmd = new-Object System.Data.SqlClient.SqlCommand("aspnet_Membership_CreateUser", $conn)

	$cmd.CommandType = [System.Data.CommandType]::StoredProcedure
    add-param $cmd "@ApplicationName" ([System.Data.ParameterDirection]::Input) [System.Data.SqlDbType]::NVarChar "EPiServerSample"
    add-param $cmd "@UserName" ([System.Data.ParameterDirection]::Input) [System.Data.SqlDbType]::NVarChar "epiadmin"
    add-param $cmd "@Password" ([System.Data.ParameterDirection]::Input) [System.Data.SqlDbType]::NVarChar "QrHyCl1HOhIZYOxfDPZX3DSWf/8pJl9Hhp5c4V4/B/MZAXJjBb/vxJCwPXsPEIaIn5LbqqVogQgyEd/ftj5Vzg=="
    add-param $cmd "@PasswordSalt" ([System.Data.ParameterDirection]::Input) [System.Data.SqlDbType]::NVarChar "+d13eQe9Iv0NrNBM6uIRrg=="
    add-param $cmd "@Email" ([System.Data.ParameterDirection]::Input) [System.Data.SqlDbType]::NVarChar "epiadmin@meridium.se"
    add-param $cmd "@PasswordQuestion" ([System.Data.ParameterDirection]::Input) [System.Data.SqlDbType]::NVarChar ""
    add-param $cmd "@PasswordAnswer" ([System.Data.ParameterDirection]::Input) [System.Data.SqlDbType]::NVarChar ""
    add-param $cmd "@IsApproved" ([System.Data.ParameterDirection]::Input) [System.Data.SqlDbType]::Bit true
    add-param $cmd "@UniqueEmail" ([System.Data.ParameterDirection]::Input) [System.Data.SqlDbType]::Int 1
    add-param $cmd "@PasswordFormat" ([System.Data.ParameterDirection]::Input) [System.Data.SqlDbType]::Int 1
    add-param $cmd "@CurrentTimeUtc" ([System.Data.ParameterDirection]::Input) [System.Data.SqlDbType]::DateTime ((get-date).ToUniversalTime())
    add-param $cmd "@UserId" ([System.Data.ParameterDirection]::Output) [System.Data.SqlDbType]::UniqueIdentifier $null
    $userId=$cmd.Parameters["@UserId"]
    $userId.Size=100
	$cmd.ExecuteNonQuery()
    echo $userId.Value
}
function add-role{ param($conn, $roleName)
	$cmd = new-Object System.Data.SqlClient.SqlCommand("aspnet_Roles_CreateRole", $conn)

	$cmd.CommandType = [System.Data.CommandType]::StoredProcedure
    add-param $cmd "@ApplicationName" ([System.Data.ParameterDirection]::Input) [System.Data.SqlDbType]::NVarChar "EPiServerSample"
    add-param $cmd "@RoleName" ([System.Data.ParameterDirection]::Input) [System.Data.SqlDbType]::NVarChar $roleName
    $cmd.ExecuteNonQuery()
}

function add-user-to-roles{ param($conn, $roleNames)
	$cmd = new-Object System.Data.SqlClient.SqlCommand("aspnet_UsersInRoles_AddUsersToRoles", $conn)

	$cmd.CommandType = [System.Data.CommandType]::StoredProcedure
    add-param $cmd "@ApplicationName" ([System.Data.ParameterDirection]::Input) [System.Data.SqlDbType]::NVarChar "EPiServerSample"
    add-param $cmd "@UserNames" ([System.Data.ParameterDirection]::Input) [System.Data.SqlDbType]::NVarChar "epiadmin"
    add-param $cmd "@RoleNames" ([System.Data.ParameterDirection]::Input) [System.Data.SqlDbType]::NVarChar $roleNames
    add-param $cmd "@CurrentTimeUtc" ([System.Data.ParameterDirection]::Input) [System.Data.SqlDbType]::DateTime ((get-date).ToUniversalTime())
    $cmd.ExecuteNonQuery()
}
function add-permission-for-role{ param($conn, $role,$contentId)
	$cmd = new-Object System.Data.SqlClient.SqlCommand("netContentAclAdd", $conn)

	$cmd.CommandType = [System.Data.CommandType]::StoredProcedure
    add-param $cmd "@Name" ([System.Data.ParameterDirection]::Input) [System.Data.SqlDbType]::NVarChar $role
    add-param $cmd "@IsRole" ([System.Data.ParameterDirection]::Input) [System.Data.SqlDbType]::Int 1
    add-param $cmd "@ContentId" ([System.Data.ParameterDirection]::Input) [System.Data.SqlDbType]::Int $contentId
    add-param $cmd "@AccessMask" ([System.Data.ParameterDirection]::Input) [System.Data.SqlDbType]::Int 63
    $cmd.ExecuteNonQuery()
}