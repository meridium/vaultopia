using System.ComponentModel.DataAnnotations;
using EPiServer.Core;
using EPiServer.DataAbstraction;
using EPiServer.DataAnnotations;
using EPiServer.Web;
using ImageVault.EPiServer;
using ProcessMap.EPiServer.Common;

namespace Vaultopia.Web.Models.Pages
{
    [ContentType(DisplayName = "ResponsiveProcess", GUID = "e3ee5699-abdd-4c99-a5d3-066676125b3a", Description = "")]
    public class ResponsiveProcess : SitePageData
    {
        [Editable(true)]
        [Display(
             Name = "Process",
             Description = "The process describing how we work.",
             GroupName = SystemTabNames.Content)]
        public virtual ProcessMapDataType ProcessMap { get; set; }


    }
}
