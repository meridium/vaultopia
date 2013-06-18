using ImageVault.Common.Data;

namespace Vaultopia.Web.Controllers {
    public class Slide {
        /// <summary>
        /// Gets or sets the large image.
        /// </summary>
        /// <value>
        /// The large image.
        /// </value>
        public WebMedia LargeImage { get; set; }

        /// <summary>
        /// Gets or sets the small image.
        /// </summary>
        /// <value>
        /// The small image.
        /// </value>
        public WebMedia SmallImage { get; set; }
    }
}