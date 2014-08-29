using EPiServer.Core;
using ImageVault.Common.Data;

namespace Vaultopia.Web.Models.Blocks {
    public interface ITeaserBlockViewModel<T> {
        /// <summary>
        ///     Gets or sets the block.
        /// </summary>
        /// <value>
        ///     The block.
        /// </value>
        T Block { get; set; }

        /// <summary>
        ///     Gets or sets the page.
        /// </summary>
        /// <value>
        ///     The page.
        /// </value>
        PageData Page { get; set; }

        /// <summary>
        ///     Gets or sets the web media.
        /// </summary>
        /// <value>
        ///     The web media.
        /// </value>
        WebMedia WebMedia { get; set; }
    }
}