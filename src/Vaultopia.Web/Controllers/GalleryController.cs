using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using EPiServer;
using EPiServer.Core;
using EPiServer.Framework.DataAnnotations;
using EPiServer.Web.Mvc;
using Vaultopia.Web.Models.Pages;

namespace Vaultopia.Web.Controllers {
    public class GalleryController : PageController<GalleryPage> {
        public ActionResult Index(GalleryPage currentPage) {
            /* Implementation of action. You can create your own view model class that you pass to the view or
             * you can pass the page type for simpler templates */

            return View(currentPage);
        }
    }
}