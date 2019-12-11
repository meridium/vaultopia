using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using System.Web.Script.Serialization;
using EPiServer.ServiceLocation;
using EPiServer.Web.Mvc;
using EPiServer.Web.Routing;
using ImageVault.Client;
using Vaultopia.Web.Models.Formats;
using Vaultopia.Web.Models.Pages;
using Vaultopia.Web.Models.ViewModels;
using Vaultopia.Web.ToIV;

namespace Vaultopia.Web.Controllers
{
    public class StartPageController : PageControllerBase<StartPage>
    {
        private readonly Client _client;

        /// <summary>
        /// Gets the image slides.
        /// </summary>
        /// <value>
        /// The image slides.
        /// </value>
        public IList<Dictionary<string, string>> ImageSlides
        {
            get
            {
                if (_imageSlides == null)
                {
                    var slides = new List<Dictionary<string, string>>();
                    // Fetch the current page
                    var pageRouteHelper = ServiceLocator.Current.GetInstance<IPageRouteHelper>();
                    var currentPage = pageRouteHelper.Page as StartPage;
                    if (currentPage?.PushMediaList != null && currentPage.PushMediaList.Count > 0)
                    {
                        var slideImages = _client.Load<PushImage>(currentPage.PushMediaList.Select(x => x.Id))
                            .UsedOn(currentPage, nameof(currentPage.PushMediaList))
                            .ToList();

                        slides.AddRange(slideImages.Select(slide => new Dictionary<string, string>
                        {
                            {"large", slide.Slide.Url}, {"medium", slide.MediumSlide.Url}, {"small", slide.SmallSlide.Url}
                        }));
                        _imageSlides = slides;
                    }
                }
                return _imageSlides;
            }
        }
        private IList<Dictionary<string, string>> _imageSlides;

        /// <summary>
        ///     Indexes the specified current page.
        /// </summary>
        /// <param name="currentPage">The current page.</param>
        /// <returns></returns>
        public ActionResult Index(StartPage currentPage)
        {

            //Connect the view models testimonial properties to the start page's to make it editable
            var editHints = ViewData.GetEditHints<PageViewModel<StartPage>, StartPage>();
            editHints.AddConnection(m => m.Layout.FirstTestimonial, p => p.FirstSiteTestimonial);
            editHints.AddConnection(m => m.Layout.SecondTestimonial, p => p.SecondSiteTestimonial);

            string firstSlideUrl = null;
            if (ImageSlides.Any())
            {
                var firstOrDefault = ImageSlides.FirstOrDefault();
                if (firstOrDefault != null)
                {
                    firstSlideUrl = firstOrDefault
                            .Where(x => x.Key == "large")
                            .Select(x => x.Value.ToString())
                            .FirstOrDefault();
                }
            }
            var viewModel = new StartPageViewModel<StartPage>(currentPage)
            {
                FirstSlideUrl = firstSlideUrl,
                Slides = new JavaScriptSerializer().Serialize(ImageSlides)
            };
            return View(viewModel);
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="StartPageController" /> class.
        /// </summary>
        public StartPageController()
        {
            _client = ClientFactory.GetSdkClient();
        }
    }
}