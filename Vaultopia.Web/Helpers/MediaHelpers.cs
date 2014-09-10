﻿using System.Collections.Generic;
using System.Web.Mvc;
using System.Web.Routing;
using EPiServer.BaseLibrary;
using ImageVault.Client;
using ImageVault.Common.Data;
using ImageVault.EPiServer;
using System.Linq;
using ImageVault.Client.Query;
using Vaultopia.Web.Business.Channels;

using System.Web.Script.Serialization;

namespace Vaultopia.Web.Helpers
{
    public static class MediaHelpers
    {
        /// <summary>
        ///     Renders the media.
        /// </summary>
        /// <param name="helper"></param>
        /// <param name="mediaReference">The media reference.</param>
        /// <param name="metaData"></param>
        /// <returns></returns>
        public static MvcHtmlString RenderMedia(this HtmlHelper helper, MediaReference mediaReference, object metaData)
        {
            var _client = ClientFactory.GetSdkClient();
            var settings = new PropertyMediaSettings();

            if (metaData != null)
            {
                var routeValueDictionary = new RouteValueDictionary(metaData);
                if (routeValueDictionary.ContainsKey("propertySettings"))
                {
                    var propertySettings = routeValueDictionary["propertySettings"];
                    if (propertySettings != null)
                    {
                        var propertySettingsAsString = propertySettings.ToString();
                        if (!string.IsNullOrEmpty(propertySettingsAsString))
                        {
                            settings = (PropertyMediaSettings)new JavaScriptSerializer().Deserialize(propertySettingsAsString, typeof(PropertyMediaSettings));
                        }
                    }
                }

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
                var mediaItems = new List<MediaItem>();
                var largeImage = GetMedia(query, settings.Width, settings.Height, settings.ResizeMode);
                var mediumImage = GetMedia(query, 350, settings.Height, settings.ResizeMode);
                var smallImage = GetMedia(query, 250, settings.Height, settings.ResizeMode);


                mediaItems.Add(new MediaItem()
                {
                    MediaVersion = MediaItem.Version.Alternate,
                    MediaSource = largeImage.Url,
                    BreakPoint = "(min-width: 495px)"
                });

                mediaItems.Add(new MediaItem()
                 {
                     MediaVersion = MediaItem.Version.Default,
                     MediaSource = smallImage.Url,
                     BreakPoint = string.Empty
                 });

                mediaItems.Add(new MediaItem()
                {
                    MediaVersion = MediaItem.Version.Alternate,
                    MediaSource = mediumImage.Url,
                    BreakPoint = "(min-width: 430px)"
                });

                var pictureTag = new TagBuilder("picture");
                foreach (var mediaItem in mediaItems.Where(m => m.MediaVersion == MediaItem.Version.Alternate))
                {
                    var sourceTag = new TagBuilder("source");
                    sourceTag.Attributes.Add("media", mediaItem.BreakPoint);
                    sourceTag.Attributes.Add("srcset", mediaItem.MediaSource);
                    pictureTag.InnerHtml += sourceTag.ToString(TagRenderMode.Normal);
                }
                foreach (var mediaItem in mediaItems.Where(m => m.MediaVersion == MediaItem.Version.Default))
                {
                    var imageTag = new TagBuilder("img");
                    imageTag.Attributes.Add("alt", string.Empty);
                    imageTag.Attributes.Add("src", mediaItem.MediaSource);
                    pictureTag.InnerHtml += imageTag.ToString(TagRenderMode.Normal);
                }

                return new MvcHtmlString(pictureTag.ToString(TagRenderMode.Normal));

                //// Videos cannot be cropped so if settings.ResizeMode is ScaleToFill we'll get null
                //// Execute the query
                //var media = query.Resize(settings.Width, settings.Height, settings.ResizeMode).SingleOrDefault() ??
                //                 query.Resize(settings.Width, settings.Height).SingleOrDefault();
                //return new MvcHtmlString(media == null ? string.Empty : media.Html);
            }
            catch
            {
                return MvcHtmlString.Empty;
            }
        }

        private static WebMedia GetMedia(IIVQueryable<WebMedia> query, int width, int height, ResizeMode resizeMode)
        {
            var media = query.Resize(width, height, resizeMode).SingleOrDefault() ??
                        query.Resize(width, height).SingleOrDefault();
            return media;
        }

        private class MediaItem
        {
            public string BreakPoint { get; set; }
            public string MediaSource { get; set; }
            public Version MediaVersion { get; set; }

            public enum Version
            {
                Default,
                Alternate
            }
        }

    }

}
