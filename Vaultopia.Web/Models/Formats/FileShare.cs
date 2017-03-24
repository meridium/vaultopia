using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using ImageVault.Common.Data;

namespace Vaultopia.Web.Models.Formats
{
    public class FileShare
    {
        public string FileName { get; set; }
        public string FileUrl { get; set; }
        public string FileShareUrl { get; set; }
    }

}