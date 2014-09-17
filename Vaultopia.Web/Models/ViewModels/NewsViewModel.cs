using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using ImageVault.Common.Data;
using Vaultopia.Web.Models.Pages;

namespace Vaultopia.Web.Models.ViewModels
{
    public class NewsPageViewModel<T> : PageViewModel<T> where T : SitePageData
    {
        public NewsPageViewModel(T page)
            : base(page)
        {
        }

        public WebMedia WebMedia;
    }
}