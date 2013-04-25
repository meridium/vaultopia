using System.Web.Mvc;

namespace Vaultopia.Web.Models.ViewModels
{
    public class LayoutModel
    {
        /// <summary>
        /// Gets or sets the login URL.
        /// </summary>
        /// <value>
        /// The login URL.
        /// </value>
        public MvcHtmlString LoginUrl { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether [logged in].
        /// </summary>
        /// <value>
        ///   <c>true</c> if [logged in]; otherwise, <c>false</c>.
        /// </value>
        public bool LoggedIn { get; set; }
    }
}