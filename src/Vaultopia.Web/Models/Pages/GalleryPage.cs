using System.ComponentModel.DataAnnotations;
using EPiServer.Core;
using EPiServer.DataAbstraction;
using EPiServer.DataAnnotations;
using EPiServer.Web;

namespace Vaultopia.Web.Models.Pages {
    [ContentType(DisplayName = "Gallery", GUID = "f8b2c441-9e8c-4173-9d47-559e8c2a2fe9", Description = "")]
    public class GalleryPage : PageData {
        
        [CultureSpecific]
        [Required]
        [Display(Name = "Heading", GroupName = SystemTabNames.Content, Order = 1)]
        public virtual string Heading { get; set; }

        [CultureSpecific]
        [Display(Name = "Introduction", GroupName = SystemTabNames.Content, Order = 2)]
        [UIHint(UIHint.Textarea)]
        public virtual string Introduction { get; set; }
    }
}