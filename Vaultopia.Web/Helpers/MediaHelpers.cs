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
using ImageVault.Common.Data.Query;
using ImageVault.Common.Data.Effects;
using ImageVault.Common.Services;

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
                var mediaItems = new List<MediaItem>();
                var standardFormat = new ImageFormat();
                var mediumFormat = new ImageFormat();
                var smallFormat = new ImageFormat();

                foreach (var effect in mediaReference.Effects)
                {
                    standardFormat.Effects.Add(effect);
                    mediumFormat.Effects.Add(effect);
                    smallFormat.Effects.Add(effect);
                }

                standardFormat.Effects.Add(new ResizeEffect(settings.Width, settings.Height, settings.ResizeMode));
                mediumFormat.Effects.Add(new ResizeEffect(800, settings.Height, settings.ResizeMode));
                smallFormat.Effects.Add(new ResizeEffect(400, settings.Height, settings.ResizeMode));

                var mediaQuery = new MediaItemQuery
                {
                    Filter = { Id = new List<int> { mediaReference.Id } },
                    Populate =
                    {
                        MediaFormats = { smallFormat, mediumFormat, standardFormat },
                        PublishIdentifier = _client.PublishIdentifier
                    }
                };
                
                var mediaService = _client.CreateChannel<IMediaService>();
                var media = mediaService.Find(mediaQuery).Single();
            
                //Add images as mediaitems
                mediaItems.Add(new MediaItem()
                {
                    MediaVersion = MediaItem.Version.Alternate,
                    MediaSource = media.MediaConversions[2].Url,
                    BreakPoint = "(min-width: 768px)"
                });
                mediaItems.Add(new MediaItem()
                {
                    MediaVersion = MediaItem.Version.Alternate,
                    MediaSource = media.MediaConversions[1].Url,
                    BreakPoint = "(min-width: 400px)"
                });
                mediaItems.Add(new MediaItem()
                 {
                     MediaVersion = MediaItem.Version.Default,
                     MediaSource = media.MediaConversions[0].Url,
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
        //private static WebMedia GetMedia(IIVQueryable<WebMedia> query, int width, int height, ResizeMode resizeMode)
        //{
        //    //// Videos cannot be cropped so if settings.ResizeMode is ScaleToFill we'll get null
        //    //// Execute the query
        //    var media = query.Resize(width, height, resizeMode).SingleOrDefault() ??
        //                query.Resize(width, height).SingleOrDefault();
        //    return media;
        //}

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

