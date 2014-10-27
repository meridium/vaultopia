using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using EPiServer.Editor;
using EPiServer.Web.Mvc;
using ImageVault.Client;
using ImageVault.Common.Data;
using Vaultopia.Web.Business.Media;
using Vaultopia.Web.Models.Formats;
using Vaultopia.Web.Models.Pages;
using Vaultopia.Web.Models.ViewModels;
using ImageVault.Common.Services;
using ImageVault.Common.Data.Query;
using ImageVault.Common.Data.Effects;

namespace Vaultopia.Web.Controllers {
    public class ArticleController : PageController<Article> {
        private readonly Client _client;

        /// <summary>
        ///     Indexes the specified current page.
        /// </summary>
        /// <param name="currentPage">The current page.</param>
        /// <returns></returns>
        public ActionResult Index(Article currentPage) {
          
            var slides = new List<Slide>();
            var mediaService = _client.CreateChannel<IMediaService>();
            var viewModel = new ArticleViewModel<Article>(currentPage);
            var formats = Formats();
            
            if (currentPage.SlideMediaList != null && currentPage.SlideMediaList.Count > 0) {

                var mediaReferences = currentPage.SlideMediaList.Take(5);
                var imageSlides = mediaReferences.Select(mediaReference => mediaReference.Id).ToList();

                var query = new MediaItemQuery
                {
                    Filter = { Id = imageSlides},
                    Populate =
                    {
                        PublishIdentifier = _client.PublishIdentifier
                    }
                };

                foreach (var imageFormat in formats)
                {
                    query.Populate.MediaFormats.Add(imageFormat.Value);
                }

                var mediaItems = mediaService.Find(query).ToList();
                foreach (var mediaItem in mediaItems)
                {
                    if (mediaItem == null)
                    {
                        continue;
                    }
                    var slide = new Slide();
                    for (var i = 0; i < mediaItem.MediaConversions.Count; i++)
                    {
                        var media = mediaItem.MediaConversions[i];

                        if (media == null)
                        {
                            continue;
                        }

                        switch (i)
                        {
                            case 0:
                                slide.SmallImage = media;
                                break;
                            case 1:
                                slide.MobileImage = media;
                                break;
                            case 2:
                                slide.MediumImage = media;
                                break;
                            case 3:
                                slide.LargeImage = media;
                                break;
                        }
                    }
                    slides.Add(slide);
                }
                viewModel.Slides = slides;
            }
            if (currentPage.SharedFile != null || Request.Url != null)
            {
                var shared = new MediaShare()
                {
                    MediaFormatId = 1,
                    Name = "Shared Files",
                    Items = new List<MediaItem>() {new MediaItem() {Id = currentPage.SharedFile.Id}}
                };
                _client.Store(shared);
                var baseUrl = Request.Url.GetLeftPart(UriPartial.Authority);
                viewModel.FileShare = baseUrl + "/imagevault/shares/" + shared.Id;
            }
            else
            {
                viewModel.FileShare = string.Empty;
            }
            return View(viewModel);
        }

        public Dictionary<ImageConversions.ImageFormats, ImageFormat> Formats()
        {
            var formats = new Dictionary<ImageConversions.ImageFormats, ImageFormat>
            {
                {ImageConversions.ImageFormats.SmallFormat, new ImageFormat()},
                {ImageConversions.ImageFormats.MobileFormat, new ImageFormat()},
                {ImageConversions.ImageFormats.MediumFormat, new ImageFormat()},
                {ImageConversions.ImageFormats.LargeFormat, new ImageFormat()}
            };

            foreach (var format in formats)
            {
                var version = format.Key;
                switch (version)
                {
                    case ImageConversions.ImageFormats.SmallFormat:
                        format.Value.Effects.Add(new ResizeEffect(ImageSizes.SmallImage.Width, ImageSizes.SmallImage.Height, ResizeMode.ScaleToFill));
                        break;
                    case ImageConversions.ImageFormats.MobileFormat:
                        format.Value.Effects.Add(new ResizeEffect(ImageSizes.MobileImage.Width, ImageSizes.MobileImage.Height, ResizeMode.ScaleToFill));
                        break;
                    case ImageConversions.ImageFormats.MediumFormat:
                        format.Value.Effects.Add(new ResizeEffect(ImageSizes.MediumImage.Width, ImageSizes.MediumImage.Height, ResizeMode.ScaleToFill));
                        break;
                    case ImageConversions.ImageFormats.LargeFormat:
                        format.Value.Effects.Add(new ResizeEffect(ImageSizes.LargeImage.Width, ImageSizes.LargeImage.Height, ResizeMode.ScaleToFill));
                        break;
                }
            }

            return formats;
        }

        /// <summary>
        ///     Renders the placeholder.
        /// </summary>
        /// <returns></returns>
        public ActionResult RenderPlaceholder() {
            // Only show the placeholder if the page is in edit mode
            if (!PageEditing.PageIsInEditMode) {
                return new EmptyResult();
            }

            return
                Content(
                    "");
        }
        /// <summary>
        /// Initializes a new instance of the <see cref="ArticleController" /> class.
        /// </summary>
        public ArticleController() {
            _client = ClientFactory.GetSdkClient();
        }
    }
}