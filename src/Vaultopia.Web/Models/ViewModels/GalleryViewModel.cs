using System.Collections.Generic;
using Vaultopia.Web.Models.Formats;
using Vaultopia.Web.Models.Pages;

namespace Vaultopia.Web.Models.ViewModels {
    public class GalleryViewModel<T> : PageViewModel<T> where T : SitePageData {
        /// <summary>
        ///     Initializes a new instance of the <see cref="GalleryViewModel{T}" /> class.
        /// </summary>
        /// <param name="page">The page.</param>
        public GalleryViewModel(T page)
            : base(page) {}

        /// <summary>
        ///     Gets or sets the images.
        /// </summary>
        /// <value>
        ///     The images.
        /// </value>
        public List<GalleryImage> Images { get; set; }
    }
}