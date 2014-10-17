using System;
using System.Collections.Generic;
using System.Web.Mvc;
using System.Web.Routing;
using EPiServer.Web;
using ImageVault.Client;
using ImageVault.Common.Data;
using ImageVault.EPiServer;
using System.Linq;
using Vaultopia.Web.Models.Formats;
using System.Web.Script.Serialization;
using ImageVault.Common.Data.Query;
using ImageVault.Common.Data.Effects;
using ImageVault.Common.Services;
using Vaultopia.Web.Business.Media;

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
                var mediaService = _client.CreateChannel<IMediaService>();
                var formats = Formats(settings, mediaReference);

                var query = new MediaItemQuery
                {
                    Filter = { Id = new List<int> { mediaReference.Id } },
                    Populate =
                    {
                        PublishIdentifier = _client.PublishIdentifier
                    }
                };

                foreach (var imageFormat in formats)
                {
                    query.Populate.MediaFormats.Add(imageFormat.Value);
                }
                
                var media = mediaService.Find(query).Single();
                var mediaItems = MediaItems(media);
                var pictureTag = PictureTag(mediaItems);
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
        /// Create list of imageformats and set values
        /// </summary>
        /// <param name="settings"></param>
        /// <param name="mediaReference"></param>
        /// <returns></returns>
        private static Dictionary<ImageConversions.ImageFormats, ImageFormat> Formats(PropertyMediaSettings settings, MediaReference mediaReference)
        {
            var formats = new Dictionary<ImageConversions.ImageFormats, ImageFormat>
            {
                {ImageConversions.ImageFormats.MobileFormat, new ImageFormat()},
                {ImageConversions.ImageFormats.MediumFormat, new ImageFormat()},
                {ImageConversions.ImageFormats.StandardFormat, new ImageFormat()}
            };

            foreach (var effect in mediaReference.Effects)
            {
                foreach (var format in formats)
                {
                    format.Value.Effects.Add(effect);
                }
            }

            foreach (var format in formats)
            {
                var version = format.Key;
                switch (version)
                {
                    case ImageConversions.ImageFormats.MobileFormat:
                        format.Value.Effects.Add(new ResizeEffect(ImageSizes.MobileImage.Width, settings.Height, settings.ResizeMode));
                        break;
                    case ImageConversions.ImageFormats.MediumFormat:
                        format.Value.Effects.Add(new ResizeEffect(ImageSizes.MediumImage.Width, settings.Height, settings.ResizeMode));
                        break;
                    case ImageConversions.ImageFormats.StandardFormat:
                        format.Value.Effects.Add(new ResizeEffect(settings.Width, settings.Height, settings.ResizeMode));
                        break;
                }
            }
            return formats;
        }

        /// <summary>
        /// Create list of mymedia
        /// </summary>
        /// <param name="media"></param>
        /// <returns></returns>
        private static List<MyMedia> MediaItems(MediaItem media)
        {
            //Add images as mediaitems
            var mediaItems = new List<MyMedia>
            {
                new MyMedia()
                {
                    MediaVersionType = MyMedia.VersionType.Alternate,
                    MediaSource = media.MediaConversions[2].Url,
                    BreakPoint = "(min-width: 768px)"
                },
                new MyMedia()
                {
                    MediaVersionType = MyMedia.VersionType.Alternate,
                    MediaSource = media.MediaConversions[1].Url,
                    BreakPoint = "(min-width: 400px)"
                },
                new MyMedia()
                {
                    MediaVersionType = MyMedia.VersionType.Default,
                    MediaSource = media.MediaConversions[0].Url,
                    BreakPoint = string.Empty
                }
            };

            return mediaItems;
        }

        /// <summary>
        /// building picturetag
        /// </summary>
        /// <param name="mediaItemList"></param>
        /// <returns></returns>
        private static TagBuilder PictureTag(List<MyMedia> mediaItemList)
        {
            var pictureTag = new TagBuilder("picture");
            foreach (var mediaItem in mediaItemList.Where(m => m.MediaVersionType == MyMedia.VersionType.Alternate))
            {
                var sourceTag = new TagBuilder("source");
                sourceTag.Attributes.Add("media", mediaItem.BreakPoint);
                sourceTag.Attributes.Add("srcset", mediaItem.MediaSource);
                pictureTag.InnerHtml += sourceTag.ToString(TagRenderMode.Normal);
            }
            foreach (var mediaItem in mediaItemList.Where(m => m.MediaVersionType == MyMedia.VersionType.Default))
            {
                var imageTag = new TagBuilder("img");
                imageTag.Attributes.Add("alt", string.Empty);
                imageTag.Attributes.Add("src", mediaItem.MediaSource);
                pictureTag.InnerHtml += imageTag.ToString(TagRenderMode.Normal);
            }

            return pictureTag;
        }

        /// <summary>
        /// get external url
        /// </summary>
        /// <param name="input"></param>
        /// <returns></returns>
        public static string GetExternalUrl(string input)
        {
            var uriBuilder = new UriBuilder(SiteDefinition.Current.SiteUrl) { Path = input };
            return uriBuilder.Uri.AbsoluteUri;
        }

        private class MyMedia
        {
            public string BreakPoint { get; set; }
            public string MediaSource { get; set; }
            public VersionType MediaVersionType { get; set; }

            public enum VersionType
            {
                Default,
                Alternate
            }
        }
    }

}

