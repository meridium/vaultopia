using ImageVault.Client.Descriptors.Effects;
using ImageVault.Common.Data;

namespace Vaultopia.Web.Models.Formats {
    public class GalleryImage : MediaItem {

        /// <summary>
        /// The original
        /// </summary>
        public Image Original { get; set; }

        /// <summary>
        /// Gets or sets the thumbnail.
        /// </summary>
        /// <value>
        /// The thumbnail.
        /// </value>
        [ResizeEffect(Width=486)]
        public Thumbnail Thumbnail { get; set; }
        
    }
}