#ImageVault.EPiServer.UI

Contains UI components for ImageVault Connect for Episerver

##Known issues

###Custom views web.config
This package contains default [display templates][1] for the ImageVault properties when using MVC. 
These templates are included in the modules views folder (/modules/_protected/ImageVault.EPiServer.UI/views).

Upon installation, the web.config from the /views folder is copied to the modules views folder. If you 
change the web.config in the /views folder, these changes are not automatically updated in the modules 
views folder. Be advised to update it manually if needed.

[1]: http://imagevault.se/en/documentation/api-documentation/?page=episerverplugin/mvc-display-templates.html