#README
See the documentation at <http://imagevault.se/doc> for more information.

##EPiServer CMS integration
See <http://imagevault.se/en/documentation/api-documentation/?page=episerverplugin/> for more information.

##Media Handlers
This package needs two handlers registered in web.config.
Those are normally added by the nuget package (if using nuget 2.6 or later) and are only needed if running in Plugin only mode 
(ie. No ui is installed in the /imagevault path). See the following link for further information.
<http://imagevault.se/en/documentation/api-documentation/?page=installation/manual-installation/episervercms7-plugin-only-installation.html>

If those handlers are missing from web.config you can add them manually. See example below. 

	<configuration>
	  <system.webServer>
	    <handlers>
	      <add name="ImageVaultMediaHandler" verb="GET" path="imagevault/media/*/*" type="ImageVault.Client.Web.MediaProxyHandler,ImageVault.Client"/>
	      <add name="ImageVaultPublishedMediaHandler" verb="GET" path="imagevault/publishedmedia/*/*" type="ImageVault.Client.Web.PublishedMediaProxyHandler,ImageVault.Client"/>
	    </handlers>
	  </system.webServer>
	</configuration>
