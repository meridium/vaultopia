using System.Web.Mvc;
using EPiServer.Web.Mvc;
using Vaultopia.Web.Models.Pages;
using Vaultopia.Web.Models.ViewModels;

namespace Vaultopia.Web.Controllers
{
    public class NewsController : PageController<NewsPage>
    {
        public ActionResult Index(NewsPage currentPage)
        {
            /* Implementation of action. You can create your own view model class that you pass to the view or
             * you can pass the page type for simpler templates */
            var viewModel = new NewsViewModel<NewsPage>(currentPage);

            return View(viewModel);
        }
    }
}