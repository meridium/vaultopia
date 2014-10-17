namespace Vaultopia.Web.Models.Formats
{
    public class ImageConversions
    {
        public ImageFormats Formats { get; set; }

        public enum ImageFormats
        {
            SmallFormat,
            MobileFormat,
            StandardFormat,
            MediumFormat,
            LargeFormat
        }
    }
}