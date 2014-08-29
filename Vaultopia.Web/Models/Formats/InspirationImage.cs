using ImageVault.Client.Descriptors.Effects;
using ImageVault.Common.Data;

namespace Vaultopia.Web.Models.Formats {
    public class InspirationImage : MediaItem {
        /// <summary>
        ///     The original
        /// </summary>
        [ResizeEffect(Width = 486)]
        public Image Preview { get; set; }

        /// <summary>
        ///     Gets or sets the thumbnail.
        /// </summary>
        /// <value>
        ///     The thumbnail.
        /// </value>
        [ResizeEffect(Width = 119, Height = 113, ResizeMode = ResizeMode.ScaleToFill)]
        public Thumbnail Thumbnail { get; set; }
    }
}