using EPiServer.ServiceLocation;
using EPiServer.Web.Routing;
using EPiServer.Web.WebControls;
using ImageVault.Client;
using ImageVault.Common.Data;
using ImageVault.EPiServer;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using ImageVault.Client.Query;
using Vaultopia.Web.Models.Pages;
using Vaultopia.Web.Models.ViewModels;
using System.Web.Helpers;
using EPiServer.Core;

namespace Vaultopia.Web.Helpers
{
    public static class MediaHelpers
    {
        /// <summary>
        ///     Renders the media.
        /// </summary>
        /// <param name="mediaReference">The media reference.</param>
        /// <returns></returns>
        public static string RenderMedia(MediaReference mediaReference)
        {
            var _client = new Client();
            // Fetch the current page
            var pageRouteHelper = ServiceLocator.Current.GetInstance<PageRouteHelper>();
            var currentPage = pageRouteHelper.Page;
            //var propertyName = string.Empty;
            var settings = new PropertyMediaSettings();

            // Load the property settings for the media reference
      
            var propertyName = currentPage.Property.Where(x => Equals(x.Value, mediaReference)).Select(x => x.Name).SingleOrDefault();
            var propertyData = currentPage.Property[propertyName];
            try
            {
                settings = (PropertyMediaSettings) propertyData.GetSetting(typeof (PropertyMediaSettings));
            }
            catch
            {
                return string.Empty;
            }

            try
            {
                // Start building the query for the specific media
                var query = _client.Load<WebMedia>(mediaReference.Id);

                // Apply editorial effects
                if (mediaReference.Effects.Count > 0)
                {
                    query = query.ApplyEffects(mediaReference.Effects);
                }

                // Videos cannot be cropped so if settings.ResizeMode is ScaleToFill we'll get null
                // Execute the query
                var media = query.Resize(settings.Width, settings.Height, settings.ResizeMode).SingleOrDefault() ??
                                 query.Resize(settings.Width, settings.Height).SingleOrDefault();
                return media == null ? string.Empty : media.Html;
            }
            catch
            {
                // Handle error with some kind of placeholder thingy
                return string.Empty;
            }
        }

    }
}