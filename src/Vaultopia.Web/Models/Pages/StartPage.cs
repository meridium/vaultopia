using System;
using System.ComponentModel.DataAnnotations;
using EPiServer.Core;
using EPiServer.DataAbstraction;
using EPiServer.DataAnnotations;
using EPiServer.SpecializedProperties;

namespace Vaultopia.Web.Models.Pages
{
    [ContentType(DisplayName = "Home", GUID = "2c4be70b-20cf-4e10-ad51-52bdd98b99f7", Description = "")]
    public class StartPage : PageData
    {
        
                [CultureSpecific]
                [Editable(true)]
                [Display(
                    Name = "Main body",
                    Description = "The main body will be shown in the main content area of the page, using the XHTML-editor you can insert for example text, images and tables.",
                    GroupName = SystemTabNames.Content,
                    Order = 1)]
                public virtual XhtmlString MainBody { get; set; }


         
    }
}