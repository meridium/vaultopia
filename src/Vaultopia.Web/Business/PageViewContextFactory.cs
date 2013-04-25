using System.Web.Mvc;
using System.Web.Routing;
using System.Web.Security;
using EPiServer.Core;
using EPiServer.Web.Routing;
using Vaultopia.Web.Models.ViewModels;

namespace Vaultopia.Web.Business
{
    public class PageViewContextFactory
    {
        private readonly UrlResolver _urlResolver;
        /// <summary>
        /// Initializes a new instance of the <see cref="PageViewContextFactory"/> class.
        /// </summary>
        /// <param name="urlResolver">The URL resolver.</param>
        public PageViewContextFactory(UrlResolver urlResolver)
        {
            _urlResolver = urlResolver;
        }

        /// <summary>
        /// Creates the layout model.
        /// </summary>
        /// <param name="currentContentLink">The current content link.</param>
        /// <param name="requestContext">The request context.</param>
        /// <returns></returns>
        public virtual LayoutModel CreateLayoutModel(ContentReference currentContentLink, RequestContext requestContext)
        {
            return new LayoutModel
            {
                LoggedIn = requestContext.HttpContext.User.Identity.IsAuthenticated,
                LoginUrl = new MvcHtmlString(GetLoginUrl(currentContentLink))
            };
        }

        /// <summary>
        /// Gets the login URL.
        /// </summary>
        /// <param name="returnToContentLink">The return to content link.</param>
        /// <returns></returns>
        private string GetLoginUrl(ContentReference returnToContentLink)
        {
            return string.Format(
                "{0}?ReturnUrl={1}",
                FormsAuthentication.LoginUrl,
                _urlResolver.GetVirtualPath(returnToContentLink));
        }
    }
}