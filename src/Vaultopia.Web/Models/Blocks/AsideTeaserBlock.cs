using System;
using System.ComponentModel.DataAnnotations;
using EPiServer.Core;
using EPiServer.DataAbstraction;
using EPiServer.DataAnnotations;
using EPiServer.Web;
using ImageVault.EPiServer;

namespace Vaultopia.Web.Models.Blocks {
    [ContentType(DisplayName = "AsideTeaserBlock", GUID = "165c5437-5906-42fa-b48f-c938af0557e8", Description = "")]
    public class AsideTeaserBlock : BlockData {
        [CultureSpecific]
        [Required(AllowEmptyStrings = false)]
        [Display(GroupName = SystemTabNames.Content, Order = 1)]
        public virtual String TeaserHeading { get; set; }

        [CultureSpecific]
        [Required(AllowEmptyStrings = false)]
        [Display(GroupName = SystemTabNames.Content, Order = 2)]
        public virtual PageReference TeaserLink { get; set; }

        [CultureSpecific]
        [Display(GroupName = SystemTabNames.Content, Order = 4)]
        [Required]
        public virtual MediaReference TeaserImage { get; set; }

        [CultureSpecific]
        [Required(AllowEmptyStrings = false)]
        [Display(GroupName = SystemTabNames.Content, Order = 5)]
        [UIHint(UIHint.Textarea)]
        public virtual String TeaserText { get; set; }

        [CultureSpecific]
        [Required(AllowEmptyStrings = false)]
        [Display(GroupName = SystemTabNames.Content, Order = 6)]
        public virtual String TeaserLocation { get; set; }

    }
}