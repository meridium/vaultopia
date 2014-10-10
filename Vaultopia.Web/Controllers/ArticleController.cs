using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using EPiServer.Editor;
using EPiServer.ServiceLocation;
using EPiServer.Web.Mvc;
using EPiServer.Web.Routing;
using ImageVault.Client;
using ImageVault.Client.Query;
using ImageVault.Common.Data;
using ImageVault.EPiServer;
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
            
            var smallFormat = new ImageFormat();
            var mobileFormat = new ImageFormat();
            var mediumFormat = new ImageFormat();
            var largeFormat = new ImageFormat();

            smallFormat.Effects.Add(new ResizeEffect(280, 184, ResizeMode.ScaleToFill));
            mobileFormat.Effects.Add(new ResizeEffect(426, 226, ResizeMode.ScaleToFill));
            mediumFormat.Effects.Add(new ResizeEffect(852, 452, ResizeMode.ScaleToFill));
            largeFormat.Effects.Add(new ResizeEffect(1420, 754, ResizeMode.ScaleToFill));
            
            if (currentPage.SlideMediaList != null && currentPage.SlideMediaList.Count > 0) {

                var mediaReferences = currentPage.SlideMediaList.Take(5);
                var imageSlides = mediaReferences.Select(mediaReference => mediaReference.Id).ToList();

                var query = new MediaItemQuery
                {
                    Filter = { Id = imageSlides},
                    Populate =
                    {
                        MediaFormats = { smallFormat, mobileFormat, mediumFormat, largeFormat },
                        PublishIdentifier = _client.PublishIdentifier
                    }
                };

                var mediaItems = mediaService.Find(query).ToList();
                foreach (var mediaItem in mediaItems)
                {
                    if (mediaItem == null)
                    {
                        continue;
                    }
                    var slide = new Slide();
                    foreach (var media in mediaItem.MediaConversions) {

                        //Create variable as Image to get width
                        var image = media as Image;

                        switch (image.Width)
                        {
                            case 280:
                                slide.SmallImage = media;
                                break;
                            case 426:
                                slide.MobileImage = media;
                                break;
                            case 852:
                                slide.MediumImage = media;
                                break;
                            case 1420:
                                slide.LargeImage = media;
                                break;
                            default:
                                break;
                        }
                    }
                    slides.Add(slide);
                  
                }
                viewModel.Slides = slides;
            }
            return View(viewModel);
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