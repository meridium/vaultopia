using System.Web.Mvc;
<<<<<<< HEAD
using EPiServer.Web.Mvc;
=======
>>>>>>> 19ffee01538cc64785005cd6f090c57151d56b4c
using Vaultopia.Web.Models.Pages;
using Vaultopia.Web.Models.ViewModels;

namespace Vaultopia.Web.Controllers {
<<<<<<< HEAD
    public class GalleryController : PageController<GalleryPage> {
        
        public GalleryController() {
            //var client =  ClientFactory.GetSdkClient();
        }

        public ActionResult Index(GalleryPage currentPage) {
            return View(currentPage);
=======
    public class GalleryController : PageControllerBase<GalleryPage> {
        public ActionResult Index(GalleryPage currentPage) {
            /* Implementation of action. You can create your own view model class that you pass to the view or
             * you can pass the page type for simpler templates */

            var viewModel = new PageViewModel<GalleryPage>(currentPage);

            return View(viewModel);
>>>>>>> 19ffee01538cc64785005cd6f090c57151d56b4c
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