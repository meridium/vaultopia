#Display templates for ImageVault properties

This folder contains the display templates for the ImageVault properties.
If you want to make your own, do not modify these since they will be overwritten when you update the ImageVault.EPiServer.UI package.

Instead, copy them to the /views/shared/displaytemplates folder and modify them there. That location has a higher preceedence than this one.

##Web.config for ImageVault display template views

The installation script for ImageVault.EPiServer.UI attempts to copy any existing web.config from /Views/Web.config into the
ImageVault display templates view folder /modules/_protected/ImageVault.EPiServer.UI/Views.

If your site's view web.config is located somewhere else, or if changes are made to the original file, you need to manually copy this file to the ImageVault display templates view folder.