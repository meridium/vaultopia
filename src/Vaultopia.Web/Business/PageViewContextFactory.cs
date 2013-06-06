using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using System.Web.Routing;
using System.Web.Security;
using EPiServer;
using EPiServer.Core;
using EPiServer.Web.Routing;
using ImageVault.Client;
using ImageVault.Client.Query;
using ImageVault.Common.Data;
using ImageVault.EPiServer;
using Vaultopia.Web.Models.Pages;
using Vaultopia.Web.Models.ViewModels;

namespace Vaultopia.Web.Business {
    public class PageViewContextFactory {
        private readonly Client _client;
        private readonly IContentLoader _contentLoader;
        private readonly UrlResolver _urlResolver;

        /// <summary>
        ///     Initializes a new instance of the <see cref="PageViewContextFactory" /> class.
        /// </summary>
        /// <param name="contentLoader">The content loader.</param>
        /// <param name="urlResolver">The URL resolver.</param>
        public PageViewContextFactory(IContentLoader contentLoader, UrlResolver urlResolver) {
            _contentLoader = contentLoader;
            _urlResolver = urlResolver;
            _client = ClientFactory.GetSdkClient(); // TODO: inject this
        }

        /// <summary>
        ///     Gets the site inspiration urls.
        /// </summary>
        /// <value>
        ///     The site inspiration urls.
        /// </value>
        protected List<string> SiteInspirationUrls {
            get {
                var startPage = _contentLoader.Get<StartPage>(ContentReference.StartPage);
                var list = new List<string>();
                if (startPage.SiteInspiration.MediaList == null) {
                    return list;
                }
                // TODO remove this and use Load<T>(IEnumerable<int>).ApplyEffects() when it is available via the API
                foreach (MediaReference mediaReference in startPage.SiteInspiration.MediaList) {
                    WebMedia media =
                        _client.Load<WebMedia>(mediaReference.Id)
                               .ApplyEffects(mediaReference.Effects)
                               .Resize(119, 113, ResizeMode.ScaleToFill)
                               .SingleOrDefault();
                    if (media == null) {
                        continue;
                    }
                    list.Add(media.Url);
                }
                return list;
            }
        }

        /// <summary>
        ///     Creates the layout model.
        /// </summary>
        /// <param name="currentContentLink">The current content link.</param>
        /// <param name="requestContext">The request context.</param>
        /// <returns></returns>
        public LayoutModel CreateLayoutModel(ContentReference currentContentLink, RequestContext requestContext) {
            var startPage = _contentLoader.Get<StartPage>(ContentReference.StartPage);

            return new LayoutModel
                {
                    FirstTestimonial = startPage.FirstSiteTestimonial,
                    SecondTestimonial = startPage.SecondSiteTestimonial,
                    SiteInspirationUrls = SiteInspirationUrls,
                    LoggedIn = requestContext.HttpContext.User.Identity.IsAuthenticated,
                    LoginUrl = new MvcHtmlString(GetLoginUrl(currentContentLink)),
                    StartPageUrl = startPage.LinkURL
                };
        }

        /// <summary>
        ///     Gets the login URL.
        /// </summary>
        /// <param name="returnToContentLink">The return to content link.</param>
        /// <returns></returns>
        private string GetLoginUrl(ContentReference returnToContentLink) {
            return string.Format(
                "{0}?ReturnUrl={1}",
                FormsAuthentication.LoginUrl,
                _urlResolver.GetVirtualPath(returnToContentLink));
        }
    }
}