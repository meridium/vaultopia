using System.ComponentModel.DataAnnotations;
using EPiServer.Core;
using EPiServer.DataAbstraction;
using EPiServer.DataAnnotations;
using EPiServer.Web;
using ImageVault.EPiServer;
using ProcessMap.EPiServer7.Property;

namespace Vaultopia.Web.Models.Pages
{
    [ContentType(DisplayName = "Process", GUID = "a3aa5699-abdd-4c99-a5d3-066676125b3c", Description = "")]
    public class Process : SitePageData
    {
        /// <summary>
        /// Gets or sets the heading.
        /// </summary>
        /// <value>
        /// The heading.
        /// </value>
        [CultureSpecific]
        [Editable(true)]
        [Display(
            Name = "Heading",
            Description = "",
            GroupName = SystemTabNames.Content,
            Order = 1)]
        public virtual string Heading { get; set; }

        /// <summary>
        /// Gets or sets the introduction.
        /// </summary>
        /// <value>
        /// The introduction.
        /// </value>
        [CultureSpecific]
        [Display(
            Name = "Introduction",
            Description = "",
            GroupName = SystemTabNames.Content,
            Order = 2)]
        [UIHint(UIHint.Textarea)]
        public virtual string Introduction { get; set; }

        /// <summary>
        /// Gets or sets the main body.
        /// </summary>
        /// <value>
        /// The main body.
        /// </value>
        [CultureSpecific]
        [Editable(true)]
        [Display(
            Name = "Main body",
            Description = "The main body will be shown in the main content area of the page, using the XHTML-editor you can insert for example text, images and tables.",
            GroupName = SystemTabNames.Content,
            Order = 3)]
        public virtual XhtmlString MainBody { get; set; }

        /// <summary>
        /// Gets or sets the teasers.
        /// </summary>
        /// <value>
        /// The teasers.
        /// </value>
        [CultureSpecific]
        [Editable(true)]
        [Display(
            GroupName = "Aside",
            Order = 1)]
        public virtual ContentArea Teasers { get; set; }

        [Editable(true)]
        [Display(
             Name = "Process",
             Description = "The process describing how we work.",
             GroupName = SystemTabNames.Content)]
        public virtual ProcessMapDataType ProcessMap { get; set; }

        [Editable(true)]
        [Display(
             Name = "ProcessMapVerticalLinePostion",
             GroupName = SystemTabNames.Content)]
        public virtual int ProcessMapVerticalLinePostion { get; set; }

        [Editable(true)]
        [Display(
             Name = "ProcessMapHorizontalLinePostion",
             GroupName = SystemTabNames.Content)]
        public virtual int ProcessMapHorizontalLinePostion { get; set; }
        /// <summary>
        /// Gets or sets the wide teasers.
        /// </summary>
        /// <value>
        /// The wide teasers.
        /// </value>
       
        [Editable(true)]
        [Display(
            GroupName = SystemTabNames.Content)]
        public virtual ContentArea WideTeasers { get; set; }

    }
}