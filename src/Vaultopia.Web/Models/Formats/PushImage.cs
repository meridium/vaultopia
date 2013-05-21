using ImageVault.Client.Descriptors.Effects;
using ImageVault.Common.Data;

namespace Vaultopia.Web.Models.Formats {
    /// <summary>
    /// Used on startpage slide show
    /// </summary>
    public class PushImage : MediaItem {
        [ResizeEffect(Width = 2400)]
        public Image Slide { get; set; }
    }
}