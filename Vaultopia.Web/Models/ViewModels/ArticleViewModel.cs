using System.Collections.Generic;
using Vaultopia.Web.Controllers;
using Vaultopia.Web.Models.Pages;

namespace Vaultopia.Web.Models.ViewModels {
    public class ArticleViewModel<T> : PageViewModel<T> where T : SitePageData {
        public ArticleViewModel(T page)
            : base(page) {
        }

        /// <summary>
        /// Gets or sets the slides.
        /// </summary>
        /// <value>
        /// The slides.
        /// </value>
        public List<Slide> Slides { get; set; }

    }
}