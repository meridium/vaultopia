using ImageVault.Client.Descriptors.Effects;
using ImageVault.Common.Data;

namespace Vaultopia.Web.Models.Formats {
    /// <summary>
    ///     Used on startpage slide show
    /// </summary>
    public class PushImage : MediaItem {
        /// <summary>
        /// Gets or sets the slide.
        /// </summary>
        /// <value>
        /// The slide.
        /// </value>
        [ResizeEffect(Width = 2400)]
        public Image Slide { get; set; }
    }
}