using ImageVault.Common.Data;
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
        public virtual List<Category> Categorys { get; set; }

        public int SelectedCategoryID { get; set; }

        internal object Where(System.Func<T, bool> func)
        {
            throw new System.NotImplementedException();
        }

    }
}