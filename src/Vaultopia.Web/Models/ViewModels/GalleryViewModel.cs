using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Vaultopia.Web.Models.Formats;
using Vaultopia.Web.Models.Pages;

namespace Vaultopia.Web.Models.ViewModels {
    public class GalleryViewModel<T> : PageViewModel<T> where T : SitePageData {
        public GalleryViewModel(T page) : base(page) {
        
        }

        public List<GalleryImage> Images { get; set; } 

    }
}