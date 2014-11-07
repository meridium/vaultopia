using System.Linq;
using System.Web.Mvc;
using EPiServer;
using EPiServer.Core;
using EPiServer.Framework.DataAnnotations;
using EPiServer.Framework.Web;
using EPiServer.Web.Mvc;
using ImageVault.Client.Query;
using ImageVault.Common.Data;
using Vaultopia.Web.Models.Pages;
using Vaultopia.Web.Models.ViewModels;
using ImageVault.Client;

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
                if (currentContentArea == startPage["WideTeasers"])
                {
                    media = _client.Load<WebMedia>(currentPage.PartialImage.Id)
                        .ApplyEffects(currentPage.PartialImage.Effects)
                        .Resize(237, 167, ResizeMode.ScaleToFill)
                        .SingleOrDefault();
                }
                else
                {
                    media = _client.Load<WebMedia>(currentPage.PartialImage.Id)
                        .ApplyEffects(currentPage.PartialImage.Effects)
                        .Resize(218, 138, ResizeMode.ScaleToFill)
                        .SingleOrDefault();
                }
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