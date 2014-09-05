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

            var viewModel = new ArticleViewModel<Article>(currentPage);

            if (currentPage.SlideMediaList != null && currentPage.SlideMediaList.Count > 0) {

                var mediaReferences = currentPage.SlideMediaList.Take(5);

                foreach (var mediaReference in mediaReferences) {
                    var slide = new Slide
                        {
                            SmallImage =
                                _client.Load<WebMedia>(mediaReference.Id)
                                       .ApplyEffects(mediaReference.Effects)
                                       .Resize(280, 184, ResizeMode.ScaleToFill)
                                       .SingleOrDefault(),
                            LargeImage =
                                _client.Load<WebMedia>(mediaReference.Id)
                                       .ApplyEffects(mediaReference.Effects)
                                       .Resize(1420, 754, ResizeMode.ScaleToFill)
                                       .SingleOrDefault()
                        };
                    if (slide.LargeImage == null || slide.SmallImage == null) {
                        continue;
                    }
                    slides.Add(slide);
                }

                viewModel.Slides = slides;
            }

            return View(viewModel);
        }

        /// <summary>
        ///     Renders the media.
        /// </summary>
        /// <param name="mediaReference">The media reference.</param>
        /// <returns></returns>
        public string RenderMedia(MediaReference mediaReference) {
            // Fetch the current page
            var pageRouteHelper = ServiceLocator.Current.GetInstance<PageRouteHelper>();
            var currentPage = pageRouteHelper.Page;

            // Load the property settings for the media reference
            var propertyData = currentPage.Property["Media"];
            if (propertyData == null)
            {
                return string.Empty;
            }
            var settings = (PropertyMediaSettings) propertyData.GetSetting(typeof (PropertyMediaSettings));


            try {
                // Start building the query for the specific media
                var query = _client.Load<WebMedia>(mediaReference.Id);

                // Apply editorial effects
                if (mediaReference.Effects.Count > 0) {
                    query = query.ApplyEffects(mediaReference.Effects);
                }

                // Videos cannot be cropped so if settings.ResizeMode is ScaleToFill we'll get null
                // Execute the query
                var media = query.Resize(settings.Width, settings.Height, settings.ResizeMode).SingleOrDefault() ??
                                 query.Resize(settings.Width, settings.Height).SingleOrDefault();
                return media == null ? string.Empty : media.Html;
            } catch {
                // Handle error with some kind of placeholder thingy
                return string.Empty;
            }
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