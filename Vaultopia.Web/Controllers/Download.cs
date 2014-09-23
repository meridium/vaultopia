using ImageVault.Common.Data;

namespace Vaultopia.Web.Controllers
{
    public class Download
    {
 
        /// <summary>
        /// Gets or sets the png image.
        /// </summary>
        /// <value>
        /// The png image.
        /// </value>
        public WebMedia PngImage { get; set; }
        /// <summary>
        /// Gets or sets the jpg image.
        /// </summary>
        /// <value>
        /// The jpg image.
        /// </value>
        public WebMedia JpgImage { get; set; }
        /// <summary>
        /// Gets or sets the gif image.
        /// </summary>
        /// <value>
        /// The gif image.
        /// </value>
        public WebMedia GifImage { get; set; }
   
    }
}