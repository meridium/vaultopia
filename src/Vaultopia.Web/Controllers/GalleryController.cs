﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Web;
using System.Web.Mvc;
using ImageVault.Client;
using ImageVault.Client.Query;
using ImageVault.Common.Data;
using ImageVault.Common.Data.Query;
using ImageVault.Common.Services;
using Vaultopia.Web.Models;
using Vaultopia.Web.Models.Formats;
using Vaultopia.Web.Models.Pages;
using Vaultopia.Web.Models.ViewModels;


namespace Vaultopia.Web.Controllers {

    public class Foo : Controller {
        
        public ActionResult Save() {
            return Content("sdf");
        }

    }
    public class GalleryController : PageControllerBase<GalleryPage> {
        private readonly Client _client;

        /// <summary>
        /// Initializes a new instance of the <see cref="GalleryController" /> class.
        /// </summary>
        public GalleryController() {
            _client = ClientFactory.GetSdkClient();
        }

        /// <summary>
        /// Indexes the specified current page.
        /// </summary>
        /// <param name="currentPage">The current page.</param>
        /// <returns></returns>
        public ActionResult Index(GalleryPage currentPage) {
            var viewModel = new GalleryViewModel<GalleryPage>(currentPage) {
                    Images = _client.Query<GalleryImage>().Where(m => m.VaultId == 1).OrderByDescending(m => m.DateAdded).Take(32).ToList()
                };

            return View(viewModel);
        }

        public ActionResult Load(GalleryPage currentPage, int skip) {

            var viewModel = new GalleryViewModel<GalleryPage>(currentPage) {
                Images = _client.Query<GalleryImage>().Where(m => m.VaultId == 1).OrderByDescending(m => m.DateAdded).Skip(skip * 32).Take(33).ToList()
            };

            return PartialView("_Images", viewModel);
        }

        /// <summary>
        /// Uploads this instance.
        /// </summary>
        /// <returns></returns>
        public ActionResult Upload() {
            return PartialView("Upload");
        }

        /// <summary>
        /// Saves the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
    
        [HttpPost]
        public ActionResult Save(UploadModel model) {
            
            //Why can't I load the mediaitem with the same id i just saved...?
            var mediaItem = _client.Load<MediaItem>(Int32.Parse(model.Id)).Include(x => x.Metadata.Where(md => md.DefinitionType == MetadataDefinitionTypes.User)).FirstOrDefault();

            if (mediaItem == null) {
                return new EmptyResult();
            }

            SaveMetadataTest(mediaItem, model.Title);

            var service = _client.CreateChannel<IMediaService>();

            service.Save(new List<MediaItem> { mediaItem }, MediaServiceSaveOptions.MarkAsOrganized);

            var image = _client.Load<GalleryImage>(mediaItem.Id).SingleOrDefault();

            if (image != null) {
                return PartialView("_Image", image);
            }

            return new EmptyResult();

        }

        /// <summary>
        /// Uploads the file.
        /// </summary>
        /// <param name="file">The file.</param>
        /// <returns></returns>
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

           

            var mediaId = mediaItem.Id;

            MediaItem poll = null;
            while (poll == null) {
                poll = _client.Query<MediaItem>().Where(x => x.Id == mediaId).Where("MediaItemState:" + MediaItemStates.MediaReadyToUse).FirstOrDefault();
                Thread.Sleep(1000);
            }

            var image = _client.Load<Image>(mediaItem.Id).Resize(222, 222, ResizeMode.ScaleToFill).SingleOrDefault();

            if (image != null) {
                var response = new { mediaItem.Id, image.Url };
                return Json(response);
            }
            
            return null;
        }


        /// <summary>
        /// Shows the meta data.
        /// </summary>
        /// <param name="imageId">The image id.</param>
        /// <returns></returns>
        public ActionResult ShowMetaData(int imageId) {
            var model = _client.Load<GalleryImage>(imageId).FirstOrDefault();
            return PartialView("_MetaData", model);
        }

        public void SaveMetadataTest(MediaItem item, string title) {
            var client = _client;

            //Yuck! Metadata handling is ugly so far.

            //create or find the metadata definition that you want to store
            //here we create the one we need if it isn't found
            var template = new MetadataDefinition {
                MetadataDefinitionType = MetadataDefinitionTypes.User,
                Name = "Title",
                MetadataType = MetadataTypes.String
            };
            var mds = client.CreateChannel<IMetadataDefinitionService>();
            //first find all metadata definitions of the same def type and type as the one requested and that matches the name.
            var definition = mds.Find(new MetadataDefinitionQuery {
                Filter = {
                    MetadataDefinitionType = template.MetadataDefinitionType,
                    MetadataType = template.MetadataType
                }
            }).FirstOrDefault(d => d.Name == template.Name);
            if (definition == null) {
                //if no match was found, create the template instead
                var id = mds.Save(template);
                definition = template;
                definition.Id = id;
            }
            //create the metadata itself by setting the id of the definition and the value (important to create a metadata of 
            //the same sort as the defined MetadataType.
            var m = new MetadataString {
                MetadataDefinitionId = definition.Id,
                StringValue = title
            };

            //when we save the metadata we only want to modify the new one
            //when we clear the metadata, this will not clear the metadata stored in the db only for this copy
            if (item.Metadata != null) {
                item.Metadata.Clear();
            }
            
            //add the new/modified metadata
            item.Metadata.Add(m);
            var ms = client.CreateChannel<IMediaService>();
            //supply the Metadata save option flag to indicate that medatata should be saved as well.
            //as stated above, we cannot delete any metadata. Any metadata passed to the save function will only 
            //be added/modified for now.
            ms.Save(new List<MediaItem> { item }, MediaServiceSaveOptions.Metadata);
        }

    }
}