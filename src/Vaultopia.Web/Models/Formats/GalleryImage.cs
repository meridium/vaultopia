using ImageVault.Client.Descriptors.Effects;
using ImageVault.Common.Data;

namespace Vaultopia.Web.Models.Formats {
    public class GalleryImage : MediaItem {
        [ResizeEffect(Width=486)]
        public Thumbnail Thumbnail { get; set; }
    }
}