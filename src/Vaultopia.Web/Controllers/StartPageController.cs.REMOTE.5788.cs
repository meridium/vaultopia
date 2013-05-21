using System;
using System.Linq;
using System.Web.Mvc;
using EPiServer.Web.Mvc;
using ImageVault.Client;
using Vaultopia.Web.Models.Formats;
using Vaultopia.Web.Models.Pages;
using Vaultopia.Web.Models.ViewModels;

namespace Vaultopia.Web.Controllers {
    public class StartPageController : PageControllerBase<StartPage> {

        private Client _client;

        /// <summary>
        /// 
        /// </summary>
        /// <param name="currentPage">The current page.</param>
        /// <returns></returns>
        public ActionResult Index(StartPage currentPage) {
            //Connect the view models testimonial properties to the start page's to make it editable
            var editHints = ViewData.GetEditHints<PageViewModel<StartPage>, StartPage>();
            editHints.AddConnection(m => m.Layout.FirstTestimonial, p => p.FirstSiteTestimonial);
            editHints.AddConnection(m => m.Layout.SecondTestimonial, p => p.SecondSiteTestimonial);

            var viewModel = new StartPageViewModel<StartPage>(currentPage) {
                                                                               FirstSlideUrl = GetFirstSlideUrl(currentPage)
                                                                           };
            return View(viewModel);
        }


        /// <summary>
        /// Initializes a new instance of the <see cref="StartPageController"/> class.
        /// </summary>
        public StartPageController() {
            _client = ClientFactory.GetSdkClient();
        }

        /// <summary>
        /// Gets the first slide URL.
        /// </summary>
        /// <param name="currentPage">The current page.</param>
        /// <returns></returns>
        public string GetFirstSlideUrl(StartPage currentPage) {
            var mediaRef = currentPage.PushMediaList.FirstOrDefault();
            if(mediaRef != null) {
                var image = _client.Load<PushImage>(mediaRef.Id).FirstOrDefault();
                if (image != null) {
                    return image.Slide.Url;
                }
            }
            return String.Empty;
        }

        public string GetSlidesAsJson(StartPage currentPage) {

            //var list = _client.Query<PushImage>().Where(x => currentPage.PushMediaList.Select(m => m.Id).Contains(x.Id)).ToList();

            var json = currentPage.PushMediaList.Select(x => new {
                                                                     Url = _client.Load<PushImage>(x.Id).FirstOrDefault().Slide.Url
                                                                 }).ToList();
            
                
           

            return String.Empty;
        }

    }
}