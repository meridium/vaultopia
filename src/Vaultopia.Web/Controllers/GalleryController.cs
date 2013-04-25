using System.Web.Mvc;
using EPiServer.Web.Mvc;
using Vaultopia.Web.Models.Pages;

namespace Vaultopia.Web.Controllers {
    public class GalleryController : PageController<GalleryPage> {
        
        public ActionResult Index(GalleryPage currentPage) {
            return View(currentPage);
        }
        public ActionResult Upload(GalleryPage currentPage) {
            return PartialView("Upload");
        }
    }
}