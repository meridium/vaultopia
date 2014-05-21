using System.Collections.Generic;
using System.Linq;
using EPiServer;
using EPiServer.Core;
using EPiServer.Filters;
using EPiServer.Framework.Web;
using EPiServer.ServiceLocation;

namespace Vaultopia.Web.Business {
    public static class ContentExtensions {
        /// <summary>
        ///     Filters for display.
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="contents">The contents.</param>
        /// <param name="requirePageTemplate">
        ///     if set to <c>true</c> [require page template].
        /// </param>
        /// <param name="requireVisibleInMenu">
        ///     if set to <c>true</c> [require visible in menu].
        /// </param>
        /// <returns></returns>
        public static IEnumerable<T> FilterForDisplay<T>(this IEnumerable<T> contents, bool requirePageTemplate = false,
                                                         bool requireVisibleInMenu = false) where T : IContent {
            var accessFilter = new FilterAccess();
            var publishedFilter = new FilterPublished(ServiceLocator.Current.GetInstance<IContentRepository>());
            contents = contents.Where(x => !publishedFilter.ShouldFilter(x) && !accessFilter.ShouldFilter(x));
            if (requirePageTemplate) {
                var templateFilter = ServiceLocator.Current.GetInstance<FilterTemplate>();
                templateFilter.TemplateTypeCategories = TemplateTypeCategories.Page;
                contents = contents.Where(x => !templateFilter.ShouldFilter(x));
            }
            if (requireVisibleInMenu) {
                contents = contents.Where(x => VisibleInMenu(x));
            }
            return contents;
        }

        /// <summary>
        ///     Visibles the in menu.
        /// </summary>
        /// <param name="content">The content.</param>
        /// <returns></returns>
        private static bool VisibleInMenu(IContent content) {
            var page = content as PageData;
            return page == null || page.VisibleInMenu;
        }
    }
}