using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Web;
using System.Web.Mvc;
using System.Web.Services;
using EPiServer.ServiceLocation;
using EPiServer.Web.Routing;
using ImageVault.Client;
using ImageVault.Client.Query;
using ImageVault.Common.Data;
using ImageVault.Common.Data.Query;
using ImageVault.Common.Services;
using Vaultopia.Web.Models;
using Vaultopia.Web.Models.Formats;
using Vaultopia.Web.Models.Pages;
using Vaultopia.Web.Models.ViewModels;
using Vaultopia.Web.Business.Media;
using System.Web.Script.Serialization;

namespace Vaultopia.Web.Controllers
{
    public class GalleryController : PageControllerBase<GalleryPage>
    {
        private readonly Client _client;

        /// <summary>
        /// Indexes the specified current page.
        /// </summary>
        /// <param name="currentPage"></param>
        /// <param name="category"></param>
        /// <param name="searchImage"></param>
        /// <returns></returns>
        public ActionResult Index(GalleryPage currentPage, int category = 0, string searchImage = null)
        {

            var viewModel = new GalleryViewModel<GalleryPage>(currentPage);
            var allImages = _client.Query<GalleryImage>().Where(m => m.VaultId == int.Parse(currentPage.VaultPicker)).OrderByDescending(m => m.DateAdded);

            if (category > 0)

            {
                allImages = allImages.Where(m => m.Categories.Contains(category));
            }

            if (!string.IsNullOrEmpty(searchImage))
            {
                allImages = allImages.SearchFor(searchImage);
            }
            viewModel.Images = allImages.ToList();

            //Get te categorys to dropdownlist.
            viewModel.Categorys =
                _client.Query<Category>().Include(x => x.IsUsed).ToList().Where(x => x.IsUsed.HasValue).ToList();
            viewModel.SelectedCategoryID = category;

            return View(viewModel);
        }

        /// <summary>
        /// Creates images to be downloaded
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [WebMethod]
        public string Download(int id)
        {
            var mediaService = _client.CreateChannel<IMediaService>();
            var formats = Formats();
            var query = new MediaItemQuery
            {
                Filter = { Id = new List<int> { id } },
                Populate =
                {
                    PublishInfo = new PublishInfo(_client.PublishIdentifier,new PublishDetailsData("Download",null,"Gallery download"))
                }
            };

            foreach (var format in formats)
            {
                query.Populate.MediaFormats.Add(format);
            }

            var mediaItem = mediaService.Find(query).Single();

            if (mediaItem == null)
            {
                return string.Empty;
            }

            var downloadList = DownloadList(mediaItem);

            return new JavaScriptSerializer().Serialize(downloadList);
        }

        /// <summary>
        /// Create list of image formats
        /// </summary>
        /// <returns></returns>
        private static IEnumerable<ImageFormat> Formats()
        {
            var formats = new List<ImageFormat>()
            {
               {new ImageFormat(){MediaFormatOutputType = MediaFormatOutputTypes.Gif}},
               {new ImageFormat(){MediaFormatOutputType = MediaFormatOutputTypes.Jpeg}},
               {new ImageFormat(){MediaFormatOutputType = MediaFormatOutputTypes.Png}}
            };

            foreach (var fileType in formats.ToList())
            {
                formats.Add(new ImageFormat()
                {
                    MediaFormatOutputType = fileType.MediaFormatOutputType,
                    Width = ImageSizes.MediumImage.Width
                });
                formats.Add(new ImageFormat()
                {
                    MediaFormatOutputType = fileType.MediaFormatOutputType,
                    Width = ImageSizes.MobileImage.Width
                });
            }
            return formats;
        }

        /// <summary>
        /// creates list of Download
        /// </summary>
        /// <param name="mediaItem"></param>
        /// <returns></returns>
        private static IEnumerable<Download> DownloadList(MediaItem mediaItem)
        {
            var downloadList = new List<Download>();
            string[] formats = { "Jpeg", "Png", "Gif" };
            foreach (var format in formats)
            {
                foreach (var conversion in mediaItem.MediaConversions)
                {
                    var image = conversion as Image;
                    if (image == null || !conversion.ContentType.Contains(format.ToLower()))
                    {
                        continue;
                    }
                    string linkName;
                    switch (image.FormatWidth)
                    {
                        case ImageSizes.MobileImage.Width:
                            linkName = "Small Size";
                            break;
                        case ImageSizes.MediumImage.Width:
                            linkName = "Medium Size";
                            break;
                        default:
                            linkName = "Original Size";
                            image.FormatWidth = image.Width;
                            break;
                    }
                    downloadList.Add(new Download
                    {
                        Format = format,
                        LinkName = linkName,
                        Width = image.FormatWidth,
                        Height = image.Height,
                        Url = conversion.Url + "?download=1"
                    });
                }
            }
            return downloadList;
        }

        /// <summary>
        /// Loads the specified current page.
        /// </summary>
        /// <param name="currentPage">The current page.</param>
        /// <param name="skip">The skip.</param>
        /// <returns></returns>
        public ActionResult Load(GalleryPage currentPage, int skip)
        {
            var viewModel = new GalleryViewModel<GalleryPage>(currentPage)
            {
                Images =
                    _client.Query<GalleryImage>()
                        .Where(m => m.VaultId == int.Parse(currentPage.VaultPicker))
                        .OrderByDescending(m => m.DateAdded)
                        .Skip(skip * 32)
                        .Take(33)
                        .ToList()
            };

            return PartialView("_Images", viewModel);
        }

        /// <summary>
        /// Uploads this instance.
        /// </summary>
        /// <returns></returns>
        public ActionResult Upload()
        {
            return PartialView("Upload");
        }

        /// <summary>
        /// Saves the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult Save(UploadModel model)
        {
            //Why can't I load the mediaitem with the same id i just saved...?
            var mediaItem =
                _client.Load<MediaItem>(Int32.Parse(model.Id))
                    .Include(x => x.Metadata.Where(md => md.DefinitionType == MetadataDefinitionTypes.User))
                    .FirstOrDefault();

            if (mediaItem == null)
            {
                return new EmptyResult();
            }

            SaveMetadataTest(mediaItem, model.Title);

            var service = _client.CreateChannel<IMediaService>();

            service.Save(new List<MediaItem> { mediaItem }, MediaServiceSaveOptions.MarkAsOrganized);

            var image = _client.Load<GalleryImage>(mediaItem.Id).SingleOrDefault();

            if (image != null)
            {
                return PartialView("_Image", image);
            }

            return new EmptyResult();

        }

        /// <summary>
        /// Uploads the file.
        /// </summary>
        /// <param name="file">The file.</param>
        /// <returns></returns>
        /// <exception cref="System.Exception">No vault found with provided id</exception>
        [HttpPost]
        public JsonResult UploadFile(HttpPostedFileBase file)
        {

            // Fetch the current page
            var pageRouteHelper = ServiceLocator.Current.GetInstance<PageRouteHelper>();
            var currentPage = pageRouteHelper.Page as GalleryPage;

            // If the current page can not be found (no VaultPicker found) use the first available vault
            var vault = currentPage != null
                ? _client.Query<Vault>().FirstOrDefault(v => v.Id == int.Parse(currentPage.VaultPicker))
                : _client.Query<Vault>().FirstOrDefault();

            if (vault == null)
            {
                throw new Exception("No vault found with provided id");
            }

            var uploadService = _client.CreateChannel<IUploadService>();

            var id = uploadService.UploadFileContent(file.InputStream, null);

            var contentservice = _client.CreateChannel<IMediaContentService>();
            var mediaItem = contentservice.StoreContentInVault(id, file.FileName, file.ContentType, vault.Id);

            var mediaId = mediaItem.Id;

            MediaItem poll = null;
            while (poll == null)
            {
                poll =
                    _client.Query<MediaItem>()
                        .Where(x => x.Id == mediaId)
                        .Where("MediaItemState:" + MediaItemStates.MediaReadyToUse)
                        .FirstOrDefault();
                Thread.Sleep(1000);
            }

            var image = _client.Load<Image>(mediaItem.Id).Resize(222, 222, ResizeMode.ScaleToFill).SingleOrDefault();

            if (image != null)
            {
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
        public ActionResult ShowMetaData(int imageId)
        {
            var model = _client.Load<GalleryImage>(imageId).FirstOrDefault();
            return PartialView("_MetaData", model);
        }

        /// <summary>
        /// Saves the metadata test.
        /// </summary>
        /// <param name="item">The item.</param>
        /// <param name="title">The title.</param>
        public void SaveMetadataTest(MediaItem item, string title)
        {
            var client = _client;

            //Yuck! Metadata handling is ugly so far.

            //create or find the metadata definition that you want to store
            //here we create the one we need if it isn't found
            var template = new MetadataDefinition
            {
                MetadataDefinitionType = MetadataDefinitionTypes.User,
                Name = "Title",
                MetadataType = MetadataTypes.String
            };
            var mds = client.CreateChannel<IMetadataDefinitionService>();
            //first find all metadata definitions of the same def type and type as the one requested and that matches the name.
            var definition = mds.Find(new MetadataDefinitionQuery
            {
                Filter =
                {
                    MetadataDefinitionType = template.MetadataDefinitionType,
                    MetadataType = template.MetadataType
                }
            }).FirstOrDefault(d => d.Name == template.Name);
            if (definition == null)
            {
                //if no match was found, create the template instead
                var id = mds.Save(template);
                definition = template;
                definition.Id = id;
            }
            //create the metadata itself by setting the id of the definition and the value (important to create a metadata of 
            //the same sort as the defined MetadataType.
            var m = new MetadataString
            {
                MetadataDefinitionId = definition.Id,
                StringValue = title
            };

            //when we save the metadata we only want to modify the new one
            //when we clear the metadata, this will not clear the metadata stored in the db only for this copy
            item.Metadata?.Clear();

            //add the new/modified metadata
            item.Metadata?.Add(m);
            var ms = client.CreateChannel<IMediaService>();
            //supply the Metadata save option flag to indicate that medatata should be saved as well.
            //as stated above, we cannot delete any metadata. Any metadata passed to the save function will only 
            //be added/modified for now.
            ms.Save(new List<MediaItem> { item }, MediaServiceSaveOptions.Metadata);
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="GalleryController" /> class.
        /// </summary>
        public GalleryController()
        {
            _client = ClientFactory.GetSdkClient();
        }


    }
}