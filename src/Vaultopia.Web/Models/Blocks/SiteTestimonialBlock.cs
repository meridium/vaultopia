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
        private readonly Client _client;

        /// <summary>
        /// Gets or sets the media.
        /// </summary>
        /// <value>
        /// The media.
        /// </value>
        public virtual MediaReference MediaReference
        {
            get
            {
                return this.GetPropertyValue(b => b.MediaReference);
            }
            set
            {
                this.SetPropertyValue(b => b.MediaReference, value);
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
                if (MediaReference == null)
                {
                    return string.Empty;
                }
                var media =
                    _client.Load<WebMedia>(MediaReference.Id).ApplyEffects(MediaReference.Effects).SingleOrDefault();
                if (media == null)
                {
                    return string.Empty;
                }
                return media.Url;
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

        /// <summary>
        /// Initializes a new instance of the <see cref="SiteTestimonialBlock"/> class.
        /// </summary>
        public SiteTestimonialBlock()
        {
            _client = ClientFactory.GetSdkClient();
        }
    }
}