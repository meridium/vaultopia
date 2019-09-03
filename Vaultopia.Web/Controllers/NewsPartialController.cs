using System.Linq;
using System.Web.Mvc;
using EPiServer;
using EPiServer.Core;
using EPiServer.Framework.DataAnnotations;
using EPiServer.Framework.Web;
using EPiServer.Web.Mvc;
using ImageVault.Common.Data;
using Vaultopia.Web.Models.Pages;
using Vaultopia.Web.Models.ViewModels;
using ImageVault.Client;
using ImageVault.EPiServer;
using Vaultopia.Web.ToIV;

namespace Vaultopia.Web.Controllers
{
    [TemplateDescriptor(TemplateTypeCategory = TemplateTypeCategories.MvcPartialController, Inherited = true)]
    public class NewsPartialController : PageController<NewsPage>
    {
        private readonly Client _client;
        public ActionResult Index(NewsPage currentPage)
        {

            var startPage = DataFactory.Instance.GetPage(PageReference.StartPage);

            //Get current contentarea for rendering
            var currentContentArea = ControllerContext.ParentActionViewContext.ViewData.Model as ContentArea;

            //Scale image different for different contentareas
            WebMedia media = null;
            if (currentPage.PartialImage != null)
            {
                var propertyMediaSettings = currentContentArea == startPage["WideTeasers"]
                    ? new PropertyMediaSettings { Width = 237, Height = 167, ResizeMode = ResizeMode.ScaleToFill }
                    : new PropertyMediaSettings { Width = 218, Height = 138, ResizeMode = ResizeMode.ScaleToFill };

                media = QueryableExtensions.UsedOn(_client.Load<WebMedia>(currentPage.PartialImage, propertyMediaSettings), currentPage, nameof(currentPage.PartialImage))
                    .SingleOrDefault();
            }

            var viewModel = new NewsViewModel<NewsPage>(currentPage)
            {
                NewsImage = media
            };
            return View("~/Views/Partials/News.cshtml", viewModel);
        }

        public NewsPartialController()
        {
            _client = ClientFactory.GetSdkClient();
        }
    }
}