using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Vaultopia.Web.Models.Formats
{
    public class DownloadJson
    {
        [JsonProperty("resolutionlist")]
        public Download Download { get; set; }
    }
}