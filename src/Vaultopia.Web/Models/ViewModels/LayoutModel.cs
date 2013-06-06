using System.Collections.Generic;
using System.Web.Mvc;
using Vaultopia.Web.Models.Blocks;

namespace Vaultopia.Web.Models.ViewModels {
    /// <summary>
    /// </summary>
    public class LayoutModel {
        /// <summary>
        ///     Gets or sets the login URL.
        /// </summary>
        /// <value>
        ///     The login URL.
        /// </value>
        public MvcHtmlString LoginUrl { get; set; }

        /// <summary>
        ///     Gets or sets a value indicating whether [logged in].
        /// </summary>
        /// <value>
        ///     <c>true</c> if [logged in]; otherwise, <c>false</c>.
        /// </value>
        public bool LoggedIn { get; set; }

        /// <summary>
        /// Gets or sets the start page URL.
        /// </summary>
        /// <value>
        /// The start page URL.
        /// </value>
        public string StartPageUrl { get; set; }

        /// <summary>
        ///     Gets or sets the first testimonial.
        /// </summary>
        /// <value>
        ///     The first testimonial.
        /// </value>
        public virtual SiteTestimonialBlock FirstTestimonial { get; set; }

        /// <summary>
        ///     Gets or sets the second testimonial.
        /// </summary>
        /// <value>
        ///     The second testimonial.
        /// </value>
        public virtual SiteTestimonialBlock SecondTestimonial { get; set; }

        /// <summary>
        ///     Gets or sets the site inspiration.
        /// </summary>
        /// <value>
        ///     The site inspiration.
        /// </value>
        public virtual SiteInspirationBlock SiteInspiration { get; set; }

        /// <summary>
        ///     Gets or sets the site inspiration urls.
        /// </summary>
        /// <value>
        ///     The site inspiration urls.
        /// </value>
        public List<string> SiteInspirationUrls { get; set; }
    }
}