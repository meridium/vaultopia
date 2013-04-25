using EPiServer.Core;
using ImageVault.Common.Data;

namespace Vaultopia.Web.Models.Blocks {
    public class TeaserBlockViewModel {
        public TeaserBlock Block { get; set; }
        public PageData Page { get; set; }
        public WebMedia WebMedia { get; set; }
    }
}