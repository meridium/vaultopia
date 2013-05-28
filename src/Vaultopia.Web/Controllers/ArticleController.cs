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
using Vaultopia.Web.Models.Formats;
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
            var viewModel = new ArticleViewModel<Article>(currentPage) {
                                                                            Slides = currentPage.SlideMediaList != null ? _client.Load<SlideImage>(currentPage.SlideMediaList.Select(x => x.Id)).Take(5).ToList() : null
                                                                       };
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