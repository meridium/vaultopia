#Deployment to INSTALL-TEST

##Prepration of the server
The following steps has been performed on the virtual server INSTALL-TEST

* Install 'IIS: Web Management Service' via Web Platform Installer (WPI)
* Activate 'Enable remote connections' from IIS Manager, in the features view of Management Service
* Start the Web Management Service from the Actions pane of the same view
* Install 'Web Deploy 3.5 for Hosting Servers' via WPI

##Preparation of the VS project

* Create a publishing profile, named 'vaultopia', with the following settings:
    * Server:       192.168.2.113
    * Sitename:     vaultopialocal
    * User name:    Administrator
    * Password:     Nr4Ce-Q1
    * Dest. URL:    http://192.168.2.113

##Updating EPiServer CMS
Updating EPi CMS is done in two steps: nuget-update and database upgrade.

###Nuget update
Perform a git-pull of the branch 'Meriworks/install-test', in order to make sure you have got the latest version of the project.
Create a new branch for the update.
Update the EPi-related nuget packages from Visual Studio, recompile the project.
When everuthing seems to be ok, publish the project to INSTALL-TEST.
Browse the site and fix problems, if any.
Push the commit/s for review.

###EPi database upgrade
If the scheme of the EPiServer database has been modified, you will have to upgrade the sites database.
Since we cannot do that directly from Visual Studio, we make an Upgrade package:

* Execute the command 'Export-EPiUpdates -Action sql' in the Packet Manager Console. A new folder, named EPiUpdatePackage will be generated under the vaultopia folder.
* Copy this folder to the corresponding folder on the server, manually, and start a command prompt in it.
* Execute the command 'update ..\Vaultopia.Web' (The argument is the path of the web-root)

If no errors are reported, the database should now be updated.

###Finalization
After a succeful review, the temporary branch shall be merged into teh branch 'meriworks/install-test', and then deleted.
