using System;
using System.ComponentModel.DataAnnotations;
using EPiServer.Core;
using EPiServer.DataAbstraction;
using EPiServer.DataAnnotations;
using EPiServer.SpecializedProperties;
using ImageVault.EPiServer;
using EPiServer.Web;

namespace Vaultopia.Web.Models.Pages
{
    [ContentType(DisplayName = "News", GUID = "2015c98e-04ae-4b59-a18c-ae988901a03a", Description = "")]
    public class NewsPage : SitePageData
    {

        /// <summary>
        /// Gets or sets the news heading.
        /// </summary>
        /// <value>
        /// The news heading.
        /// </value>
        [CultureSpecific]
        [Required(AllowEmptyStrings = false)]
        [Display(GroupName = SystemTabNames.Content, Order = 1)]
        public virtual String NewsHeading { get; set; }

        /// <summary>
        /// Gets or sets the news link.
        /// </summary>
        /// <value>
        /// The news link.
        /// </value>
        [CultureSpecific]
        [Required(AllowEmptyStrings = false)]
        [Display(GroupName = SystemTabNames.Content, Order = 2)]
        public virtual PageReference NewsLink { get; set; }

        /// <summary>
        /// Gets or sets the main image.
        /// </summary>
        /// <value>
        /// The news image.
        /// </value>
        [CultureSpecific]
        [Display(GroupName = SystemTabNames.Content, Order = 4)]
        [Required]
        public virtual MediaReference MainImage { get; set; }

        /// <summary>
        /// Gets or sets the partial image
        /// </summary>
        /// <value>
        /// The partial image.
        /// </value>
        [CultureSpecific]
        [Display(GroupName = SystemTabNames.Content, Order = 4)]
        [Required]
        public virtual MediaReference PartialImage { get; set; }

        /// <summary>
        /// Gets or sets the news text.
        /// </summary>
        /// <value>
        /// The Introtext.
        /// </value>
        [CultureSpecific]
        [Required(AllowEmptyStrings = false)]
        [Display(GroupName = SystemTabNames.Content, Order = 5)]
        [UIHint(UIHint.Textarea)]
        public virtual String IntroText { get; set; }

        /// <summary>
        /// Gets or sets the newstext
        /// </summary>
        /// <value>
        /// The newstext
        /// </value> 
        [CultureSpecific]
        [Display(GroupName = SystemTabNames.Content, Order = 5)]
        [UIHint(UIHint.Textarea)]
        public virtual XhtmlString NewsText { get; set; }

        /// <summary>
        /// Gets or sets the news location.
        /// </summary>
        /// <value>
        /// The news location.
        /// </value>
        [CultureSpecific]
        [Required(AllowEmptyStrings = false)]
        [Display(GroupName = SystemTabNames.Content, Order = 6)]
        public virtual String NewsLocation { get; set; }

        /// <summary>
        /// Gets or sets the news price.
        /// </summary>
        /// <value>
        /// The news price.
        /// </value>
        [CultureSpecific]
        [Required(AllowEmptyStrings = false)]
        [Display(GroupName = SystemTabNames.Content, Order = 6)]
        public virtual int NewsPrice { get; set; }
    }
}