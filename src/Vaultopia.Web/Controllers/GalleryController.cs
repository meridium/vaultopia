using System.Web.Mvc;
using EPiServer.Web.Mvc;
using Vaultopia.Web.Models.Pages;

namespace Vaultopia.Web.Controllers {
    public class GalleryController : PageController<GalleryPage> {
        
        public GalleryController() {
            //var client =  ClientFactory.GetSdkClient();
        }

        public ActionResult Index(GalleryPage currentPage) {
            return View(currentPage);
        }
        public ActionResult Upload() {
            return PartialView("Upload");
        }
        public ActionResult Save() {
            return Content("ok");
        }


        [HttpPost]
        public ActionResult UploadFile(HttpPostedFileBaseModelBinder file) {

            //var vault = client.Query<Vault>().Where(v => v.).FirstOrDefault();

            return Content("uploaded");
        }
    }
}