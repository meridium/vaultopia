using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using ImageVault.Client.Descriptors.Effects;
using ImageVault.Common.Data;

namespace Vaultopia.Web.Models.Formats
{

    public class FileImage : MediaItem
    {
         [ResizeEffect(Width = 30)]
        public Thumbnail SideImage { get; set; }
    }
}
