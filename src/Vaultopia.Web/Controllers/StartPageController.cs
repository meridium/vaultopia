﻿using System;
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

namespace Vaultopia.Web.Controllers {
    public class StartPageController : PageControllerBase<StartPage> {
        private readonly Client _client;

        /// <summary>
        /// Gets the image slides.
        /// </summary>
        /// <value>
        /// The image slides.
        /// </value>
        public IEnumerable<string> ImageSlides {
            get {
                if (_imageSlides == null) {
                    // Fetch the current page
                    var pageRouteHelper = ServiceLocator.Current.GetInstance<PageRouteHelper>();
                    var currentPage = pageRouteHelper.Page as StartPage;
                    if (currentPage != null && currentPage.PushMediaList != null && currentPage.PushMediaList.Count > 0) {
                        _imageSlides = _client.Load<PushImage>(currentPage.PushMediaList.Select(x => x.Id)).ToList().Select(i => i.Slide.Url).ToList();
                    }
                }
                return _imageSlides;
            }
        }
        private IEnumerable<string> _imageSlides;

        /// <summary>
        ///     Indexes the specified current page.
        /// </summary>
        /// <param name="currentPage">The current page.</param>
        /// <returns></returns>
        public ActionResult Index(StartPage currentPage) {
            //Connect the view models testimonial properties to the start page's to make it editable
            var editHints = ViewData.GetEditHints<PageViewModel<StartPage>, StartPage>();
            editHints.AddConnection(m => m.Layout.FirstTestimonial, p => p.FirstSiteTestimonial);
            editHints.AddConnection(m => m.Layout.SecondTestimonial, p => p.SecondSiteTestimonial);

            var viewModel = new StartPageViewModel<StartPage>(currentPage)
                {
                    FirstSlideUrl = ImageSlides != null ? ImageSlides.FirstOrDefault() : null,
                    Slides = new JavaScriptSerializer().Serialize(ImageSlides)
                };
            return View(viewModel);
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="StartPageController" /> class.
        /// </summary>
        public StartPageController() {
            _client = ClientFactory.GetSdkClient();
        }
    }
}