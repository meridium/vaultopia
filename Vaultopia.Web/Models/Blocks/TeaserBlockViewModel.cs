using EPiServer.Core;
using ImageVault.Common.Data;

namespace Vaultopia.Web.Models.Blocks {
    /// <summary>
    /// </summary>
    public class TeaserBlockViewModel<T> : ITeaserBlockViewModel<T> {
        /// <summary>
        ///     Gets or sets the block.
        /// </summary>
        /// <value>
        ///     The block.
        /// </value>
        public T Block { get; set; }

        /// <summary>
        ///     Gets or sets the page.
        /// </summary>
        /// <value>
        ///     The page.
        /// </value>
        public PageData Page { get; set; }

        /// <summary>
        ///     Gets or sets the web media.
        /// </summary>
        /// <value>
        ///     The web media.
        /// </value>
        public WebMedia WebMedia { get; set; }

        public WebMedia WebMedia1 { get; set; }
    }
}