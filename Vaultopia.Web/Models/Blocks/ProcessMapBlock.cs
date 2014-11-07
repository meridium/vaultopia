using System;
using System.ComponentModel.DataAnnotations;
using EPiServer.Core;
using EPiServer.DataAbstraction;
using EPiServer.DataAnnotations;
using EPiServer.Web;
using ProcessMap.EPiServer7.Common;

namespace Vaultopia.Web.Models.Blocks
{
    [ContentType(DisplayName = "ProcessMapBlock", GUID = "f8e6488e-3de4-477b-ae8b-7d19080f78d9", Description = "")]
    public class ProcessMapBlock : BlockData
    {
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
        public virtual ProcessMapDataType ProcessMap { get; set; }

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
    }

}
