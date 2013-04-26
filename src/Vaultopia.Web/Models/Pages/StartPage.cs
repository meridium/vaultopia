using System.ComponentModel.DataAnnotations;
using EPiServer.Core;
using EPiServer.DataAbstraction;
using EPiServer.DataAnnotations;
using Vaultopia.Web.Models.Blocks;

namespace Vaultopia.Web.Models.Pages {
    [ContentType(DisplayName = "Home", GUID = "2c4be70b-20cf-4e10-ad51-52bdd98b99f7", Description = "")]
    public class StartPage : SitePageData {
        
        [CultureSpecific]
        [Editable(true)]
        [Display(
            GroupName = SystemTabNames.Content,
            Order = 1)]
        public virtual ContentArea Teasers { get; set; }

        [CultureSpecific]
        [Editable(true)]
        [Display(
            GroupName = SystemTabNames.Content,
            Order = 2)]
        public virtual ContentArea WideTeasers { get; set; }

        /// <summary>
        /// Gets or sets the first site testimonial.
        /// </summary>
        /// <value>
        /// The first site testimonial.
        /// </value>
        [Display(GroupName = "Settings")]
        public virtual SiteTestimonialBlock FirstSiteTestimonial { get; set; }

        /// <summary>
        /// Gets or sets the second site testimonial.
        /// </summary>
        /// <value>
        /// The second site testimonial.
        /// </value>
        [Display(GroupName = "Settings")]
        public virtual SiteTestimonialBlock SecondSiteTestimonial { get; set; }

    }
}