using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Web;
using Vaultopia.Web.Models.Formats;
using Vaultopia.Web.Models.Pages;

namespace Vaultopia.Web.Models.ViewModels
{
    public class ProcessViewModel<T> : PageViewModel<T> where T : SitePageData
    {
        public ProcessViewModel(T page)
            : base(page){
        }

        public List<FileShare> FileList { get; set; }

    }

}