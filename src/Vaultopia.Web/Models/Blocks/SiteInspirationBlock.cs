using EPiServer.Core;
using EPiServer.DataAnnotations;
using ImageVault.EPiServer;

namespace Vaultopia.Web.Models.Blocks
{
    [ContentType(DisplayName = "SiteInspirationBlock", GUID = "1a90e258-02d0-485b-9a04-9d981ccc1d46", Description = "", AvailableInEditMode = false)]
    public class SiteInspirationBlock : BlockData
    {
        /// <summary>
        /// Gets or sets the media list.
        /// </summary>
        /// <value>
        /// The media list.
        /// </value>
        [BackingType(typeof(PropertyMediaList))]
        public virtual MediaReferenceList<MediaReference> MediaList
        {
            get
            {
                return this.GetPropertyValue(b => b.MediaList);
            }
            set
            {
                this.SetPropertyValue(b => b.MediaList, value);
            }
        }
    }
}