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
        public string Aperture {
            get {
                if (String.IsNullOrEmpty(_aperture)) {
                    return String.Empty;
                }
                decimal aperture;
                if (Decimal.TryParse(_aperture.Replace(",", "."), out aperture)) {
                    return Math.Round(aperture, 1).ToString();
                }
                return _aperture;
            }
            set {
                _aperture = value;
            }
        }
        private string _aperture;

        /// <summary>
        /// Gets or sets the exposure time.
        /// </summary>
        /// <value>
        /// The exposure time.
        /// </value>
        [Metadata(Name = "ExposureTime", Type = MetadataDefinitionTypes.Exif)]
        public string ExposureTime { 
            get {
                if (String.IsNullOrEmpty(_exposureTime)) {
                    return String.Empty;
                }
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

        /// <summary>
        /// Gets or sets the longitude.
        /// </summary>
        /// <value>
        /// The longitude.
        /// </value>
        [Metadata(Name = "GpsLongitude", Type = MetadataDefinitionTypes.Gps)]
        public string GpsLongitude { get; set; }

        /// <summary>
        /// Gets or sets the latitude.
        /// </summary>
        /// <value>
        /// The latitude.
        /// </value>
        [Metadata(Name = "GpsLatitude", Type = MetadataDefinitionTypes.Gps)]
        public string GpsLatitude { get; set; }

        /// <summary>
        /// Gets or sets the GPS longitude ref.
        /// </summary>
        /// <value>
        /// The GPS longitude ref.
        /// </value>
        [Metadata(Name = "GpsLongitudeRef", Type = MetadataDefinitionTypes.Gps)]
        public string GpsLongitudeRef { get; set; }

        /// <summary>
        /// Gets or sets the GPS latitude ref.
        /// </summary>
        /// <value>
        /// The GPS latitude ref.
        /// </value>
        [Metadata(Name = "GpsLatitudeRef", Type = MetadataDefinitionTypes.Gps)]
        public string GpsLatitudeRef { get; set; }


        [Metadata(Name = "Latitude", Type = MetadataDefinitionTypes.User)]
        public string Latitude {
            get {
                if (String.IsNullOrEmpty(_latitude)) {
                    return String.Empty;
                }

                var lat = _latitude.Replace(',', '.').Split(' ');

                if (lat.Length < 2) {
                    return String.Empty;
                }

                var degrees = Decimal.Parse(lat[0]);
                var minutes = Decimal.Parse(lat[1]);

                var decimalDegrees = minutes / 60 + degrees;

                return decimalDegrees.ToString();
            }
            set { _latitude = value; }
        }
        private string _latitude;


        [Metadata(Name = "Longitude", Type = MetadataDefinitionTypes.User)]
        public string Longitude {
            get {
                if (String.IsNullOrEmpty(_longitude)) {
                    return String.Empty;
                }

                var lng = _longitude.Replace(',', '.').Split(' ');

                if (lng.Length < 2) {
                    return String.Empty;
                }

                var degrees = Decimal.Parse(lng[0]);
                var minutes = Decimal.Parse(lng[1]);

                var decimalDegrees = minutes/60 + degrees;

                return decimalDegrees.ToString();
            }
            set { _longitude = value; }
        }
        private string _longitude;



    }
}