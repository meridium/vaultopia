using System;
using System.ComponentModel.DataAnnotations;
using EPiServer;
using EPiServer.Core;
using EPiServer.DataAbstraction;
using EPiServer.DataAnnotations;
using EPiServer.UI;
using EPiServer.XForms;
using ImageVault.EPiServer;
using Vaultopia.Web.Models.Formats;

namespace Vaultopia.Web.Models.Blocks
{
    [ContentType(DisplayName = "ContactBlock", GUID = "8BE0D5B8-8968-47E8-89B1-1B7B6FC807BE", Description = "")]
    public class ContactBlock : BlockData
    {

        [CultureSpecific]
        [Display(
            Name = "Contact",
            Description = "Name field's description",
            GroupName = SystemTabNames.Content,
            Order = 1)]
        public virtual String Name { get; set; }

        /// <summary>
        /// Info about how to contact
        /// </summary> 
        /// <value>
        /// Info
        /// </value>
        [CultureSpecific]
        public virtual XhtmlString ContactInfo { get; set; }

        /// <summary>
        /// Imagephoto for contact 1
        /// </summary> 
        /// <value>
        /// image photot
        /// </value>
        [CultureSpecific]
        public virtual MediaReference ContactImage1 { get; set; }

        /// <summary>
        /// Imagephoto for contact 2
        /// </summary> 
        /// <value>
        /// image photot
        /// </value>
        [CultureSpecific]
        public virtual MediaReference ContactImage2 { get; set; }
        
        /// <summary>
        /// Contact info for imgae 1
        /// </summary> 
        /// <value>
        /// contact info 
        /// </value>
        [CultureSpecific]
        public virtual XhtmlString MiniInfo1 { get; set; }

        /// <summary>
        /// Contact info for imgae 2
        /// </summary> 
        /// <value>
        /// contact info 
        /// </value>
        [CultureSpecific]
        public virtual XhtmlString MiniInfo2 { get; set; }

    }
}
