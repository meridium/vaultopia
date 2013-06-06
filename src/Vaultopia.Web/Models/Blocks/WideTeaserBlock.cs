using System;
using System.ComponentModel.DataAnnotations;
using EPiServer.Core;
using EPiServer.DataAbstraction;
using EPiServer.DataAnnotations;
using EPiServer.Web;
using ImageVault.EPiServer;

namespace Vaultopia.Web.Models.Blocks {
    [ContentType(DisplayName = "WideTeaserBlock", GUID = "28061444-4b36-4c6e-8e3e-fb44c79fbfcf", Description = "")]
    public class WideTeaserBlock : BlockData {
        /// <summary>
        /// Gets or sets the teaser heading.
        /// </summary>
        /// <value>
        /// The teaser heading.
        /// </value>
        [CultureSpecific]
        [Required(AllowEmptyStrings = false)]
        [Display(GroupName = SystemTabNames.Content, Order = 1)]
        public virtual String TeaserHeading { get; set; }

        /// <summary>
        /// Gets or sets the teaser link.
        /// </summary>
        /// <value>
        /// The teaser link.
        /// </value>
        [CultureSpecific]
        [Required(AllowEmptyStrings = false)]
        [Display(GroupName = SystemTabNames.Content, Order = 2)]
        public virtual PageReference TeaserLink { get; set; }

        /// <summary>
        /// Gets or sets the teaser image.
        /// </summary>
        /// <value>
        /// The teaser image.
        /// </value>
        [CultureSpecific]
        [Display(GroupName = SystemTabNames.Content, Order = 4)]
        [Required]
        public virtual MediaReference TeaserImage { get; set; }

        /// <summary>
        /// Gets or sets the teaser text.
        /// </summary>
        /// <value>
        /// The teaser text.
        /// </value>
        [CultureSpecific]
        [Required(AllowEmptyStrings = false)]
        [Display(GroupName = SystemTabNames.Content, Order = 5)]
        [UIHint(UIHint.Textarea)]
        public virtual String TeaserText { get; set; }

        /// <summary>
        /// Gets or sets the teaser location.
        /// </summary>
        /// <value>
        /// The teaser location.
        /// </value>
        [CultureSpecific]
        [Required(AllowEmptyStrings = false)]
        [Display(GroupName = SystemTabNames.Content, Order = 6)]
        public virtual String TeaserLocation { get; set; }

        /// <summary>
        /// Gets or sets the teaser price.
        /// </summary>
        /// <value>
        /// The teaser price.
        /// </value>
        [CultureSpecific]
        [Required(AllowEmptyStrings = false)]
        [Display(GroupName = SystemTabNames.Content, Order = 6)]
        public virtual int TeaserPrice { get; set; }
    }
}