using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using EPiServer.Editor;
using EPiServer.Web.Mvc;
using ImageVault.Client;
using ImageVault.Common.Data;
using ImageVault.Common.Services;
using Vaultopia.Web.Models.Formats;
using Vaultopia.Web.Models.Pages;
using Vaultopia.Web.Models.ViewModels;
using System.IO;
using Vaultopia.Web.ToIV;

namespace Vaultopia.Web.Controllers
{
    public class ProcessController : PageController<Process>
    {   private readonly Client _client;

          public ProcessController() {
            _client = ClientFactory.GetSdkClient();
        }
        /// <summary>
        ///     Indexes the specified current page.
        /// </summary>
        /// <param name="currentPage">The current page.</param>
        /// <returns></returns>
        public ActionResult Index(Process currentPage)
        {


            var viewModel = new ProcessViewModel<Process>(currentPage);
            if (currentPage.InfoDocuments == null || Request.Url == null) return View(viewModel);
            var mediaShareService = _client.CreateChannel<IMediaShareService>();
            var shareList = new List<Models.Formats.FileShare>();
            var thumbnails = _client.Load<FileImage>(currentPage.InfoDocuments.Select(x => x.Id))
                .UsedOn(currentPage,nameof(currentPage.InfoDocuments)).ToList();
            for (var i = 0; i < currentPage.InfoDocuments.Count; i++)
            {
                var shared = new MediaShare();
                var fileShare = new Models.Formats.FileShare()
                {
                    FileName = Path.GetFileNameWithoutExtension(thumbnails[i].SideImage.Name),
                    FileUrl = thumbnails[i].SideImage.Url
                };

                var mediaShares = mediaShareService.FindShareByMediaItemId(currentPage.InfoDocuments[i].Id);
                var shares = mediaShares as MediaShare[] ?? mediaShares.ToArray();

                var foundShare = shares.FirstOrDefault(x => x.Items.Count == 1);

                if (foundShare == null)
                {
                    shared.MediaFormatId = 1;
                    shared.Name = "Shared Files";
                    shared.Items = new List<MediaItem>() { new MediaItem() { Id = currentPage.InfoDocuments[i].Id } };
                }
                else
                {
                    shared = foundShare;
                }

                _client.Store(shared);
                var baseUrl = Request.Url.GetLeftPart(UriPartial.Authority);
                fileShare.FileShareUrl = baseUrl + "/imagevault/shares/" + shared.Id;
                shareList.Add(fileShare);
            }

            viewModel.FileList = shareList;
            return View(viewModel);

        }

        /// <summary>
        ///     Renders the placeholder.
        /// </summary>
        /// <returns></returns>
        public ActionResult RenderPlaceholder()
        {
            // Only show the placeholder if the page is in edit mode
            if (!PageEditing.PageIsInEditMode)
            {
                return new EmptyResult();
            }
            return Content("");
        }
    }
}