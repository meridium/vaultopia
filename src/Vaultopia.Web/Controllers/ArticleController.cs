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
                    "<div class=\"ivEmptyActions\" style=\"background-color:#fff;text-align: center; width: 100%; display: inline-block; background-position: 50% 30px; background-repeat: no-repeat; background-image: url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAIMAAABtCAIAAAANsUXDAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyBpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMC1jMDYwIDYxLjEzNDc3NywgMjAxMC8wMi8xMi0xNzozMjowMCAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENTNSBXaW5kb3dzIiB4bXBNTTpJbnN0YW5jZUlEPSJ4bXAuaWlkOjgyOUJBNUUxNkExRjExRTI5MUU3RjRCNkIyNDI5NEI5IiB4bXBNTTpEb2N1bWVudElEPSJ4bXAuZGlkOjgyOUJBNUUyNkExRjExRTI5MUU3RjRCNkIyNDI5NEI5Ij4gPHhtcE1NOkRlcml2ZWRGcm9tIHN0UmVmOmluc3RhbmNlSUQ9InhtcC5paWQ6ODI5QkE1REY2QTFGMTFFMjkxRTdGNEI2QjI0Mjk0QjkiIHN0UmVmOmRvY3VtZW50SUQ9InhtcC5kaWQ6ODI5QkE1RTA2QTFGMTFFMjkxRTdGNEI2QjI0Mjk0QjkiLz4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz6VPNUCAAAGRklEQVR42uyd6XbaMBCF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);\"><p style=\"font-weight: bold;\">Drag your ImageVault media here.</p></div>");

        }

        /// <summary>
        /// Initializes a new instance of the <see cref="ArticleController" /> class.
        /// </summary>
        public ArticleController() {
            _client = ClientFactory.GetSdkClient();
        }
    }
}