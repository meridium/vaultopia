using Vaultopia.Web.Models.Pages;

namespace Vaultopia.Web.Models.ViewModels {
    public class StartPageViewModel<T> : PageViewModel<T> where T : StartPage {
        /// <summary>
        /// Initializes a new instance of the <see cref="StartPageViewModel{T}"/> class.
        /// </summary>
        /// <param name="page">The page.</param>
        public StartPageViewModel(T page) : base(page) {
        
        }

        /// <summary>
        /// Gets or sets the first slide URL.
        /// </summary>
        /// <value>
        /// The first slide URL.
        /// </value>
        public string FirstSlideUrl { get; set; }

        /// <summary>
        /// Gets or sets the slides.
        /// </summary>
        /// <value>
        /// The slides.
        /// </value>
        public string Slides { get; set; }
    }
}