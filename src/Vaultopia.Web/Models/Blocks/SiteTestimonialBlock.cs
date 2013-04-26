using System.Linq;
using EPiServer.Core;
using EPiServer.DataAnnotations;
using ImageVault.Client;
using ImageVault.Client.Query;
using ImageVault.Common.Data;
using ImageVault.EPiServer;

namespace Vaultopia.Web.Models.Blocks
{
    [ContentType(DisplayName = "SiteTestimonialBlock", GUID = "ba4fa9b3-53cb-44e6-9f89-4b156da4c002", Description = "", AvailableInEditMode = false)]
    public class SiteTestimonialBlock : BlockData
    {
        private readonly Client _client = ClientFactory.GetSdkClient();

        /// <summary>
        /// Gets or sets the media.
        /// </summary>
        /// <value>
        /// The media.
        /// </value>
        public virtual MediaReference Media
        {
            get
            {
                return this.GetPropertyValue(b => b.Media);
            }
            set
            {
                this.SetPropertyValue(b => b.Media, value);
            }
        }

        /// <summary>
        /// Gets the media URL.
        /// </summary>
        /// <value>
        /// The media URL.
        /// </value>
        public virtual string MediaUrl
        {
            get
            {
                if (Media == null)
                {
                    return string.Empty;
                }
                return _client.Load<WebMedia>(Media.Id).ApplyEffects(Media.Effects).SingleOrDefault().Url;
            }
        }

        /// <summary>
        /// Gets or sets the site logotype title.
        /// </summary>
        /// <value>
        /// The site logotype title.
        /// </value>
        [CultureSpecific]
        public virtual string Testimonial { get; set; }
    }
}