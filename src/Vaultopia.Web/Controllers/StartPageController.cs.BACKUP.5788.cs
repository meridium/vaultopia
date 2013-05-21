using System;
using System.Linq;
using System.Web.Mvc;
<<<<<<< HEAD
using System.Web.Script.Serialization;
=======
>>>>>>> 8d190c67d1ef4a50014c9a72cc61ae375dcb5bdd
using EPiServer.Web.Mvc;
using ImageVault.Client;
using Vaultopia.Web.Models.Formats;
using Vaultopia.Web.Models.Pages;
using Vaultopia.Web.Models.ViewModels;

namespace Vaultopia.Web.Controllers {
    public class StartPageController : PageControllerBase<StartPage> {

<<<<<<< HEAD
        private readonly Client _client;
=======
        private Client _client;
>>>>>>> 8d190c67d1ef4a50014c9a72cc61ae375dcb5bdd

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
<<<<<<< HEAD
                                                                               FirstSlideUrl = GetFirstSlideUrl(currentPage),
                                                                               Slides = GetSlidesAsJson(currentPage)
=======
                                                                               FirstSlideUrl = GetFirstSlideUrl(currentPage)
>>>>>>> 8d190c67d1ef4a50014c9a72cc61ae375dcb5bdd
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

<<<<<<< HEAD
        /// <summary>
        /// Gets the slides as json.
        /// </summary>
        /// <param name="currentPage">The current page.</param>
        /// <returns></returns>
        public string GetSlidesAsJson(StartPage currentPage) {

            var list = currentPage.PushMediaList.Select(x => new {
                                                                    Url = GetImageUrl(x.Id)
                                                                 }).ToList();

            var json = new JavaScriptSerializer().Serialize(list);

            return json;
        }

        /// <summary>
        /// Gets the image URL.
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        private string GetImageUrl(int id) {
            var item = _client.Load<PushImage>(id).FirstOrDefault();
            return item != null ? item.Slide.Url : String.Empty;
        }
=======
        public string GetSlidesAsJson(StartPage currentPage) {

            //var list = _client.Query<PushImage>().Where(x => currentPage.PushMediaList.Select(m => m.Id).Contains(x.Id)).ToList();

            var json = currentPage.PushMediaList.Select(x => new {
                                                                     Url = _client.Load<PushImage>(x.Id).FirstOrDefault().Slide.Url
                                                                 }).ToList();
            
                
           

            return String.Empty;
        }

>>>>>>> 8d190c67d1ef4a50014c9a72cc61ae375dcb5bdd
    }
}