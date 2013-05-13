using System;
using ImageVault.Client.Descriptors.Effects;
using ImageVault.Common.Data;
using ImageVault.Client.Descriptors;

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
        [ResizeEffect(Width = 486)]
        public Thumbnail Thumbnail { get; set; }

        /// <summary>
        /// Gets or sets the title.
        /// </summary>
        /// <value>
        /// The title.
        /// </value>
        [Metadata(Name = "Title", Type = MetadataDefinitionTypes.User)]
        public string Title { get; set; }

        /// <summary>
        /// Gets or sets the photographer.
        /// </summary>
        /// <value>
        /// The photographer.
        /// </value>
        [Metadata(Name = "Photographer", Type = MetadataDefinitionTypes.User)]
        public string Photographer { get; set; }

        /// <summary>
        /// Gets or sets the iso.
        /// </summary>
        /// <value>
        /// The iso.
        /// </value>
        [Metadata(Name = "ISO", Type = MetadataDefinitionTypes.Exif)]
        public string Iso { get; set; }

        /// <summary>
        /// Gets or sets the length of the focal.
        /// </summary>
        /// <value>
        /// The length of the focal.
        /// </value>
        [Metadata(Name = "FocalLength", Type = MetadataDefinitionTypes.Exif)]
        public string FocalLength { get; set; }

        /// <summary>
        /// Gets or sets the aperture.
        /// </summary>
        /// <value>
        /// The aperture.
        /// </value>
        [Metadata(Name = "ApertureValue", Type = MetadataDefinitionTypes.Exif)]
        public string Aperture { get; set; }

        /// <summary>
        /// Gets or sets the exposure time.
        /// </summary>
        /// <value>
        /// The exposure time.
        /// </value>
        [Metadata(Name = "ExposureTime", Type = MetadataDefinitionTypes.Exif)]
        public string ExposureTime { 
            get {
                decimal exposure;
                if (Decimal.TryParse(_exposureTime.Replace(",","."), out exposure)) {
                    if (exposure >= 1) {
                        return String.Format("{0}\"", Convert.ToInt32(exposure));
                    }
                    return String.Format("1/{0}", Convert.ToInt32(1 / exposure));
                }
                return _exposureTime;
            }
            set {
                _exposureTime = value;
            }
        }
        private string _exposureTime;
    }
}