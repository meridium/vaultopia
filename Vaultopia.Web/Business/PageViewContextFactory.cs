using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using System.Web.Routing;
using System.Web.Security;
using EPiServer;
using EPiServer.Core;
using EPiServer.Web.Routing;
using ImageVault.Client;
using ImageVault.EPiServer;
using Vaultopia.Web.Models.Formats;
using Vaultopia.Web.Models.Pages;
using Vaultopia.Web.Models.ViewModels;

namespace Vaultopia.Web.Business
{
    public class PageViewContextFactory
    {
        private Client _client;

        public Client Client
        {
            get { return _client ?? (_client = ClientFactory.GetSdkClient()); }
        }

        private readonly IContentLoader _contentLoader;
        private readonly UrlResolver _urlResolver;

        /// <summary>
        ///     Initializes a new instance of the <see cref="PageViewContextFactory" /> class.
        /// </summary>
        /// <param name="contentLoader">The content loader.</param>
        /// <param name="urlResolver">The URL resolver.</param>
        public PageViewContextFactory(IContentLoader contentLoader, UrlResolver urlResolver)
        {
            _contentLoader = contentLoader;
            _urlResolver = urlResolver;
        }

        /// <summary>
        /// Gets the inspiration images.
        /// </summary>
        /// <value>
        /// The inspiration images.
        /// </value>
        protected List<InspirationImage> InspirationImages
        {
            get
            {
                var startPage = _contentLoader.Get<StartPage>(ContentReference.StartPage);
                _inspirationImages = new List<InspirationImage>();

                foreach (MediaReference mediaReference in startPage.SiteInspiration.MediaList)
                {
                    InspirationImage media = Client.Load<InspirationImage>(mediaReference.Id).SingleOrDefault();
                    if (media == null)
                    {
                        continue;
                    }
                    _inspirationImages.Add(media);
                }

                return _inspirationImages;
            }
        }
        private List<InspirationImage> _inspirationImages;
        /// <summary>
        ///     Creates the layout model.
        /// </summary>
        /// <param name="currentContentLink">The current content link.</param>
        /// <param name="requestContext">The request context.</param>
        /// <returns></returns>
        public LayoutModel CreateLayoutModel(ContentReference currentContentLink, RequestContext requestContext)
        {
            var startPage = _contentLoader.Get<StartPage>(ContentReference.StartPage);

            return new LayoutModel
            {
                FirstTestimonial = startPage.FirstSiteTestimonial,
                SecondTestimonial = startPage.SecondSiteTestimonial,
                SiteInspirationUrls = InspirationImages,
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
        private string GetLoginUrl(ContentReference returnToContentLink)
        {
            return string.Format(
                "{0}?ReturnUrl={1}",
                FormsAuthentication.LoginUrl,
                _urlResolver.GetUrl(returnToContentLink));
            //_urlResolver.GetVirtualPath(returnToContentLink));

        }
    }
}