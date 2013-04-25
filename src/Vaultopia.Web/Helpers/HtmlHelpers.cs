using System;
using System.Linq;
using System.Web.Mvc;
using EPiServer;
using EPiServer.Core;
using EPiServer.ServiceLocation;
using EPiServer.Web.Routing;
using Vaultopia.Web.Business;

namespace Vaultopia.Web.Helpers
{
    public static class HtmlHelpers
    {
        /// <summary>
        /// Menus the specified HTML.
        /// </summary>
        /// <param name="html">The HTML.</param>
        /// <param name="itemContent">Content of the item.</param>
        /// <param name="selectedItemContent">Content of the selected item.</param>
        /// <param name="enableDisplayInMenu">if set to <c>true</c> [enable display in menu].</param>
        /// <returns></returns>
        public static MvcHtmlString Menu(this HtmlHelper html, Func<PageData, MvcHtmlString> itemContent, Func<PageData,MvcHtmlString>  selectedItemContent, bool enableDisplayInMenu = true)
        {
            var currentContentLink = html.ViewContext.RequestContext.GetContentLink();
            var contentLoader = ServiceLocator.Current.GetInstance<IContentLoader>();
            var pages = contentLoader.GetChildren<PageData>(ContentReference.StartPage)
                                     .FilterForDisplay(true, true).ToList();
            
            pages.Insert(0, contentLoader.Get<PageData>(ContentReference.StartPage));

            var ul = new TagBuilder("ul");

            if (!pages.Any())
            {
                return MvcHtmlString.Empty;
            }

            foreach (var page in pages)
            {
                var tag = new TagBuilder("li")
                    {
                        InnerHtml =
                            page.ContentLink.CompareToIgnoreWorkID(currentContentLink)
                                ? selectedItemContent(page).ToHtmlString()
                                : itemContent(page).ToHtmlString()
                    };
                ul.InnerHtml += tag.ToString(TagRenderMode.Normal) + Environment.NewLine;
            }
            return MvcHtmlString.Create(ul.ToString());
        }
    }
}