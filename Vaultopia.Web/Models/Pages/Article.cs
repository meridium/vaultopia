﻿using System.ComponentModel.DataAnnotations;
using EPiServer;
using EPiServer.Core;
using EPiServer.DataAbstraction;
using EPiServer.DataAnnotations;
using ImageVault.Common.Data;
using ImageVault.EPiServer;

namespace Vaultopia.Web.Models.Pages
{
    [ContentType(DisplayName = "Article" +
                               "", GUID = "a3aa568f-7ddd-4cc8-a5d3-066676125b3c", Description = "")]
    public class Article : SitePageData
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
            Order = 2)]
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
            Order = 3)]
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
            Order = 4)]
        public virtual XhtmlString MainBody { get; set; }

        /// <summary>
        /// Gets or sets the media.
        /// </summary>
        /// <value>
        /// The media.
        /// </value>
        [CultureSpecific]
        [Editable(true)]
        [Display(
            Name = "Media",
            Description = "",
            GroupName = SystemTabNames.Content,
            Order = 5)]        
        public virtual MediaReference Media { get; set; }

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

        /// <summary>
        /// Gets or sets contact
        /// </summary>
        ///<value>
        /// The contact
        /// </value>
        public virtual ContentArea Contact { get; set; }
        
        /// <summary>
        /// Gets or sets the slide media list.
        /// </summary>
        /// <value>
        /// The slide media list.
        /// </value>
        [Display(GroupName = SystemTabNames.Content,
            Order = 1)]
        [BackingType(typeof(PropertyMediaList))]
        public virtual MediaReferenceList<MediaReference> SlideMediaList { get; set; }

        /// <summary>
        /// Gets or sets the shared file
        /// </summary>
        /// <value>
        /// The shared file
        /// </value>
        [Display(
        Name = "Travelers guide",
        GroupName = "Shared Files",
        Description = "Add something you'd like to share")]
        public virtual MediaReference SharedFile { get; set; }
    }
}