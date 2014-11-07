using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Vaultopia.Web.Models.Formats
{
    public class Download
    {
        [JsonProperty("linkName")]
        public string LinkName { get; set; }

        [JsonProperty("format")]
        public string Format { get; set; }

        [JsonProperty("width")]
        public int Width { get; set; }

        public int Height { get; set; }

        public string Url { get; set; }
    }
}