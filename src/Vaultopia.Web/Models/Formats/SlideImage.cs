using ImageVault.Client.Descriptors.Effects;
using ImageVault.Common.Data;

namespace Vaultopia.Web.Models.Formats {
    public class SlideImage : MediaItem {

        /// <summary>
        /// Gets or sets the slide.
        /// </summary>
        /// <value>
        /// The slide.
        /// </value>
        [ResizeEffect(Width = 710, Height = 377, ResizeMode = ResizeMode.ScaleToFill)]
        public Image LargeImage { get; set; }

        /// <summary>
        /// Gets or sets the small image.
        /// </summary>
        /// <value>
        /// The small image.
        /// </value>
        [ResizeEffect(Width = 280, Height = 91, ResizeMode = ResizeMode.ScaleToFill)]
        public Thumbnail SmallImage { get; set; }
    }
}