using System.Web.Mvc;
using System.Web.Security;
using EPiServer.Web.Mvc;
using Vaultopia.Web.Models.Pages;

namespace Vaultopia.Web.Controllers
{
    public abstract class PageControllerBase<T> : PageController<T> where T : SitePageData
    {
        /// <summary>
        /// Logouts this instance.
        /// </summary>
        /// <returns></returns>
        public ActionResult Logout()
        {
            FormsAuthentication.SignOut();
            return RedirectToAction("Index");
        }
    }
}
