using System;
using System.Collections.Generic;
using System.Web.Mvc;
using System.Web.Routing;
using EPiServer.Web;
using ImageVault.Client;
using ImageVault.Common.Data;
using ImageVault.EPiServer;
using System.Linq;
using ImageVault.Client.Query;

using System.Web.Script.Serialization;

namespace Vaultopia.Web.Helpers
{
    public static class MediaHelpers
    {
        static readonly Client _client;

        static MediaHelpers()
        {
            _client = ClientFactory.GetSdkClient();
        }

        /// <summary>
        ///     Renders the media.
        /// </summary>
        /// <param name="helper"></param>
        /// <param name="mediaReference">The media reference.</param>
        /// <param name="metaData"></param>
        /// <returns></returns>
        public static MvcHtmlString RenderMedia(this HtmlHelper helper, MediaReference mediaReference, object metaData)
        {
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

                //Create images for different resolutions
                var mediaItems = new List<MediaItem>();
                var standardImage = GetMedia(query, settings.Width, settings.Height, settings.ResizeMode);
                var mediumImage = GetMedia(query, settings.Width, settings.Height, settings.ResizeMode);
                var smallImage = GetMedia(query, settings.Width, settings.Height, settings.ResizeMode);

                //Set size for different resolutions if image is specifik size
                if (standardImage.Width > 800)
                {
                    mediumImage = GetMedia(query, 800, settings.Height, settings.ResizeMode);
                    smallImage = GetMedia(query, 400, settings.Height, settings.ResizeMode);
                
                }
                else if (standardImage.Width > 400)
                {
                    smallImage = GetMedia(query, 400, settings.Height, settings.ResizeMode);
                
                
                }

                //Add images as mediaitems
                mediaItems.Add(new MediaItem()
                {
                    MediaVersion = MediaItem.Version.Alternate,
                    MediaSource = standardImage.Url,
                    BreakPoint = "(min-width: 768px)"
                });
                mediaItems.Add(new MediaItem()
                {
                    MediaVersion = MediaItem.Version.Alternate,
                    MediaSource = mediumImage.Url,
                    BreakPoint = "(min-width: 400px)"
                });
                mediaItems.Add(new MediaItem()
                 {
                     MediaVersion = MediaItem.Version.Default,
                     MediaSource = smallImage.Url,
                     BreakPoint = string.Empty
                 });

                //Build picturetag and add content
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

                
                //var media = query.Resize(settings.Width, settings.Height, settings.ResizeMode).SingleOrDefault() ??
                //                 query.Resize(settings.Width, settings.Height).SingleOrDefault();
                //return new MvcHtmlString(media == null ? string.Empty : media.Html);
            }
            catch
            {
                return MvcHtmlString.Empty;
            }
        }
        /// <summary>
        /// Creating media
        /// </summary>
        /// <param name="query"></param>
        /// <param name="width"></param>
        /// <param name="height"></param>
        /// <param name="resizeMode"></param>
        /// <returns></returns>
        private static WebMedia GetMedia(IIVQueryable<WebMedia> query, int width, int height, ResizeMode resizeMode)
        {
            //// Videos cannot be cropped so if settings.ResizeMode is ScaleToFill we'll get null
            //// Execute the query
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

        public static string GetExternalUrl(string input)
        {
           
            var uriBuilder = new UriBuilder(SiteDefinition.Current.SiteUrl) { Path = input };


            return uriBuilder.Uri.AbsoluteUri;
        }


    }

}

