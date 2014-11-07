using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using ImageVault.Common.Data;
using Vaultopia.Web.Models.Pages;

namespace Vaultopia.Web.Models.ViewModels
{
    public class NewsViewModel<T> : PageViewModel<T> where T : SitePageData
    {
        /// <summary>
        ///     Initializes a new instance of the <see cref="NewsViewModel{T}" /> class.
        /// </summary>
        /// <param name="page">The page.</param>
        public NewsViewModel(T page)
            : base(page)
        {
        }

        /// <summary>
        ///     Gets or sets NewsImage.
        /// </summary>
        /// <value>
        ///     The NewsImage.
        /// </value>
        public WebMedia NewsImage;
    }
}