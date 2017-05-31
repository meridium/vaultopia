using System;
using System.Collections.Generic;
using System.Globalization;
using System.Web.Mvc;
using System.Web.Routing;
using EPiServer.Web;
using ImageVault.Client;
using ImageVault.Common.Data;
using ImageVault.EPiServer;
using ImageVault.EPiServer.Common;
using System.Linq;
using Vaultopia.Web.Models.Formats;
using System.Web.Script.Serialization;
using ImageVault.Common.Data.Query;
using ImageVault.Common.Data.Effects;
using ImageVault.Common.Services;
using Vaultopia.Web.Business.Media;
using Convert = MindFusion.Convert;

namespace Vaultopia.Web.Helpers
{
    public static class MediaHelpers
    {
        static readonly Client Client;

        static MediaHelpers()
        {
            Client = ClientFactory.GetSdkClient();
        }



        /// <summary>
        /// get external url
        /// </summary>
        /// <param name="input"></param>
        /// <returns></returns>
        public static string GetExternalUrl(string input)
        {
            var uriBuilder = new UriBuilder(SiteDefinition.Current.SiteUrl) { Path = input };
            return uriBuilder.Uri.AbsoluteUri;
        }

    }

}

