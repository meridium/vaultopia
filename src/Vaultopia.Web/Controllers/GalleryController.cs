using System.Web.Mvc;
using EPiServer.Web.Mvc;
using Vaultopia.Web.Models.Pages;
using Vaultopia.Web.Models.ViewModels;

namespace Vaultopia.Web.Controllers {
    public class GalleryController : PageControllerBase<GalleryPage> {
        public ActionResult Index(GalleryPage currentPage) {
            /* Implementation of action. You can create your own view model class that you pass to the view or
             * you can pass the page type for simpler templates */

            var viewModel = new PageViewModel<GalleryPage>(currentPage);

            return View(viewModel);

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
                public GalleryController() {
            //var client =  ClientFactory.GetSdkClient();
        }
    }
}