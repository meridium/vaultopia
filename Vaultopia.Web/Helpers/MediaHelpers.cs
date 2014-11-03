using System;
using System.Collections.Generic;
using System.Globalization;
using System.Web.Mvc;
using System.Web.Routing;
using EPiServer.Web;
using EPiServer.WorkflowFoundation.Activities;
using ImageVault.Client;
using ImageVault.Common.Data;
using ImageVault.EPiServer;
using System.Linq;
using ImageVault.EPiServer.Common;
using Vaultopia.Web.Models.Formats;
using System.Web.Script.Serialization;
using ImageVault.Common.Data.Query;
using ImageVault.Common.Data.Effects;
using ImageVault.Common.Services;
using Vaultopia.Web.Business.Media;
using Convert = MindFusion.Convert;

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
                    Filter = {Id = new List<int> {mediaReference.Id}},
                    Populate =
                    {
                        PublishIdentifier = _client.PublishIdentifier,
                        PublishInformation = true,
                }
            };

                foreach (var imageFormat in formats)
                {
                    query.Populate.MediaFormats.Add(imageFormat.Value);
                }

                var media = mediaService.Find(query).Single();

                if(media.MediaConversions.Last().ContentType.Contains("video"))
                {
                    return new MvcHtmlString(media.MediaConversions.Last().Html);
                }
        
                var mediaItems = MediaItems(media, settings);
                var pictureTag = PictureTag(mediaItems);
                return new MvcHtmlString(pictureTag.ToString(TagRenderMode.Normal));
                 
            }
            catch
            {
                return MvcHtmlString.Empty;
            }
        }

        /// <summary>
        /// Create dictionary of imageformats and set values
        /// </summary>
        /// <param name="settings"></param>
        /// <param name="mediaReference"></param>
        /// <returns></returns>
        private static Dictionary<ImageConversions.ImageFormats, WebMediaFormat> Formats(PropertyMediaSettings settings, MediaReferenceBase mediaReference)
        {
            var formats = new Dictionary<ImageConversions.ImageFormats, WebMediaFormat>
            {
                {ImageConversions.ImageFormats.MobileFormat, new WebMediaFormat()},
                {ImageConversions.ImageFormats.MediumFormat, new WebMediaFormat()},
                {ImageConversions.ImageFormats.StandardFormat, new WebMediaFormat()},
                {ImageConversions.ImageFormats.VideoFormat, new WebMediaFormat()}
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
                switch (format.Key)
                {
                    case ImageConversions.ImageFormats.MobileFormat:
                        format.Value.Effects.Add(new ResizeEffect(ImageSizes.MobileImage.Width, GetHeight(settings, ImageSizes.MobileImage.Width), settings.ResizeMode));
                        break;
                    case ImageConversions.ImageFormats.MediumFormat:
                        format.Value.Effects.Add(new ResizeEffect(ImageSizes.MediumImage.Width, GetHeight(settings, ImageSizes.MediumImage.Width), settings.ResizeMode));
                        break;
                    case ImageConversions.ImageFormats.StandardFormat:
                        format.Value.Effects.Add(new ResizeEffect(settings.Width, settings.Height, settings.ResizeMode));
                        break;
                    case ImageConversions.ImageFormats.VideoFormat:
                        format.Value.Effects.Add(new ResizeEffect(settings.Width, settings.Height));
                        break;
                }
            }
            return formats;
        }

        /// <summary>
        /// Create list of mymedia
        /// </summary>
        /// <param name="media"></param>
        /// <param name="settings"></param>
        /// <returns></returns>
        private static List<MyMedia> MediaItems(MediaItem media, PropertyMediaSettings settings)
        {
           
            //Add images as mediaitems
            var mediaItems = new List<MyMedia>();
            
            var myMediaStandard = new MyMedia()
                {
                    MediaVersionType = MyMedia.VersionType.Default,
                    MediaSource = media.MediaConversions[2].Url,
                    BreakPoint = string.Empty,
                };
            var myMediaMedium = new MyMedia()
                {
                    MediaVersionType = MyMedia.VersionType.Alternate,
                    MediaSource = media.MediaConversions[1].Url,
                    BreakPoint = "(max-width: 768px)",
                };
            var myMediaSmall = new MyMedia()
                {
                    MediaVersionType = MyMedia.VersionType.Alternate,
                    MediaSource = media.MediaConversions[0].Url,
                    BreakPoint = "(max-width: 400px)",
                };

            mediaItems.Add(myMediaStandard);

            //Check if it is usefull to render formats for mediaquerys
            if (settings.Width >= ImageSizes.SmallImage.Width && settings.Width >= ImageSizes.MediumImage.Width || settings.Width == 0)
            {
                mediaItems.Add(myMediaSmall);
                mediaItems.Add(myMediaMedium);
            }
            else if (settings.Width >= ImageSizes.SmallImage.Width)
            {
                mediaItems.Add(myMediaSmall);
            }

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
        /// get height of image
        /// </summary>
        /// <param name="settings"></param>
        /// <param name="width"></param>
        /// <returns></returns>
        public static int GetHeight(PropertyMediaSettings settings, int width)
        {
            if (settings.Width == 0) return 0;
            var ratio = decimal.Parse(settings.Width.ToString(CultureInfo.InvariantCulture)) / decimal.Parse(width.ToString(CultureInfo.InvariantCulture));
            var height = settings.Height / ratio;
            var convertedHeight = Convert.ToInt32(Math.Round(height).ToString(CultureInfo.InvariantCulture));
            return convertedHeight;
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

