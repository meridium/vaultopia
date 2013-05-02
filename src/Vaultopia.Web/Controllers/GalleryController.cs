using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using EPiServer.Web.Mvc;
using ImageVault.Client;
using ImageVault.Client.Query;
using ImageVault.Common.Data;
using ImageVault.Common.Services;
using Vaultopia.Web.Models;
using Vaultopia.Web.Models.Pages;
using Vaultopia.Web.Models.ViewModels;

namespace Vaultopia.Web.Controllers {
    public class GalleryController : PageControllerBase<GalleryPage> {

        private readonly Client _client;

        public GalleryController() {
            _client = ClientFactory.GetSdkClient();
        }

        public ActionResult Index(GalleryPage currentPage) {
            var viewModel = new PageViewModel<GalleryPage>(currentPage);
            return View(viewModel);
        }

        public ActionResult Upload() {
            return PartialView("Upload");
        }

        [HttpPost]
        public ActionResult Save(UploadModel model) {

            //Why can't I load the mediaitem with the same id i just saved...?
            var mediaItem = _client.Load<MediaItem>(Int32.Parse(model.Id)).FirstOrDefault();

            if (mediaItem == null) {
                return new EmptyResult();
            }

            //TODO: Update metadata...

            var service = _client.CreateChannel<IMediaService>();
            service.Save(new List<MediaItem> { mediaItem }, MediaServiceSaveOptions.MarkAsOrganized);

            //Why can't Save take an Image? Seems a little unnecessary to load both the mediaitem and image?
            var image = _client.Load<Image>(mediaItem.Id).Resize(486).SingleOrDefault();

            if (image != null) {
                return Content(image.Url);
            }

            return new EmptyResult();

        }

        [HttpPost]
        public JsonResult UploadFile(HttpPostedFileBase file) {

            //TODO: Get Vault id from some nifty place.
            var vault = _client.Query<Vault>().FirstOrDefault(v => v.Id == 1);

            if (vault == null) {
                throw new Exception("No vault found with provided id");
            }

            var uploadService = _client.CreateChannel<IUploadService>();

            var id = uploadService.UploadFileContent(file.InputStream, null);

            var contentservice = _client.CreateChannel<IMediaContentService>();
            var mediaItem = contentservice.StoreContentInVault(id, file.FileName, file.ContentType, vault.Id);

            var service = _client.CreateChannel<IMediaService>();
            service.Save(new List<MediaItem> { mediaItem }, MediaServiceSaveOptions.MarkAsOrganized);


            var image = _client.Load<Image>(mediaItem.Id).Resize(222, 222, ResizeMode.ScaleToFill).SingleOrDefault();

            if (image != null) {
                var response = new { mediaItem.Id, image.Url };
                return Json(response);
            }
            
            return null;
        }
        

    }
}