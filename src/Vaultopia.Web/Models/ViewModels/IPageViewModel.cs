﻿using Vaultopia.Web.Models.Pages;

namespace Vaultopia.Web.Models.ViewModels
{
    public interface IPageViewModel<out T> where T : SitePageData
    {
        /// <summary>
        /// Gets the current page.
        /// </summary>
        /// <value>
        /// The current page.
        /// </value>
        T CurrentPage { get; }

        /// <summary>
        /// Gets or sets the layout.
        /// </summary>
        /// <value>
        /// The layout.
        /// </value>
        LayoutModel Layout { get; set; }
    }
}
