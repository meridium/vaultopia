using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Web;
using EPiServer.XForms.WebControls;
using ImageVault.Common.Data;
using Vaultopia.Web.Models.Formats;
using Image = ImageVault.Common.Data.Image;

namespace Vaultopia.Web.Business
{
    public class Download
    {
        private static void Main(string[] args)
        {
            // Load the image.
            System.Drawing.Image image = System.Drawing.Image.FromFile(@"Model.Thumbnail.Url");

            // Save the image in JPEG format.
            image.Save(@"Model.Thumbnail.Url", System.Drawing.Imaging.ImageFormat.Jpeg);

            // Save the image in GIF format.
            image.Save(@"Model.Thumbnail.Url", System.Drawing.Imaging.ImageFormat.Gif);

            // Save the image in PNG format.
            image.Save(@"Model.Thumbnail.Url", System.Drawing.Imaging.ImageFormat.Png);
        }

    }

}