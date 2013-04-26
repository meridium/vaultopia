using EPiServer.Core;

namespace Vaultopia.Web.Models.Blocks {
    public class TeaserBlockViewModel {
        /// <summary>
        /// Gets or sets the block.
        /// </summary>
        /// <value>
        /// The block.
        /// </value>
        public TeaserBlock Block { get; set; }

        /// <summary>
        /// Gets or sets the page.
        /// </summary>
        /// <value>
        /// The page.
        /// </value>
        public PageData Page { get; set; }
    }
}