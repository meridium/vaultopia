using System;
using EPiServer.Web;

namespace Vaultopia.Web.Helpers
{
    public static class MediaHelpers
    {




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

