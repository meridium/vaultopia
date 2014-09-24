using System.Web.Mvc;
using EPiServer.Editor;
using EPiServer.Web.Mvc;
using Vaultopia.Web.Models.Pages;
using Vaultopia.Web.Models.ViewModels;

namespace Vaultopia.Web.Controllers
{
    public class ProcessController : PageController<Process>
    {

        /// <summary>
        ///     Indexes the specified current page.
        /// </summary>
        /// <param name="currentPage">The current page.</param>
        /// <returns></returns>
        public ActionResult Index(Process currentPage)
        {


            var viewModel = new PageViewModel<Process>(currentPage);


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

            return
                Content(
                    "");

        }
    }
}