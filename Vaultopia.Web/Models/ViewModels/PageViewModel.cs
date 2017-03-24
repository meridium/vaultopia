using EPiServer.Core;

namespace Vaultopia.Web.Models.ViewModels {
    public class PageViewModel<T> : IPageViewModel<T> where T : PageData {
        /// <summary>
        ///     Initializes a new instance of the <see cref="PageViewModel{T}" /> class.
        /// </summary>
        /// <param name="page">The page.</param>
        public PageViewModel(T page) {
            CurrentPage = page;
        }

        /// <summary>
        ///     Gets the current page.
        /// </summary>
        /// <value>
        ///     The current page.
        /// </value>
        public T CurrentPage { get; private set; }

        /// <summary>
        ///     Gets or sets the layout.
        /// </summary>
        /// <value>
        ///     The layout.
        /// </value>
        public LayoutModel Layout { get; set; }




        public string Files { get; set; }
    }
}