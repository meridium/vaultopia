using System;
using System.ComponentModel.DataAnnotations;
using EPiServer.Core;
using EPiServer.DataAbstraction;
using EPiServer.DataAnnotations;
using EPiServer.Web;

namespace Vaultopia.Web.Models.Blocks {
    [ContentType(DisplayName = "TeaserBlock", GUID = "04ac15bc-91ed-4b60-94bf-57001a8e4744", Description = "")]
    public class TeaserBlock : BlockData {
        
        [CultureSpecific]
        [Required(AllowEmptyStrings = false)]
        [Display(GroupName = SystemTabNames.Content, Order = 1)]
        public virtual String TeaserHeading { get; set; }

        [CultureSpecific]
        [Required(AllowEmptyStrings = false)]
        [Display(GroupName = SystemTabNames.Content, Order = 2)]
        public virtual PageReference TeaserLink { get; set; }

        /*
            [CultureSpecific]
            [Required(AllowEmptyStrings = false)]
            [Display(GroupName = SystemTabNames.Content, Order = 4)]
            public virtual String TeaserImage { get; set; }
        */

        [CultureSpecific]
        [Required(AllowEmptyStrings = false)]
        [Display(GroupName = SystemTabNames.Content, Order = 5)]
        [UIHint(UIHint.Textarea)]
        public virtual String TeaserText { get; set; }

        [CultureSpecific]
        [Required(AllowEmptyStrings = false)]
        [Display(GroupName = SystemTabNames.Content, Order = 6)]
        public virtual String TeaserLocation { get; set; }

        [CultureSpecific]
        [Required(AllowEmptyStrings = false)]
        [Display(GroupName = SystemTabNames.Content, Order = 6)]
        public virtual int TeaserPrice { get; set; }

    }
}