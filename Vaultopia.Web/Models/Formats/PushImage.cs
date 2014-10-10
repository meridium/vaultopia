using System;
using EPiServer.Shell.Web.Mvc;
using ImageVault.Client.Descriptors.Effects;
using ImageVault.Common.Data;
using Ionic.Zlib;


namespace Vaultopia.Web.Models.Formats {
    /// <summary>
    ///     Used on startpage slide show
    /// </summary>
    public class PushImage : MediaItem {
        /// <summary>
        /// Gets or sets the slide.
        /// </summary>
        /// <value>
        /// The slide.
        /// </value>
        [ResizeEffect(Width = 2400)]
        public Image Slide { get; set; }

        /// <summary>
        /// Gets or sets the medium slide.
        /// </summary>
        /// <value>
        /// The medium slide.
        /// </value>
        [ResizeEffect(Width = 1400)]
        public Image MediumSlide { get; set; }

        /// <summary>
        /// Gets or sets the small slide.
        /// </summary>
        /// <value>
        /// The small slide.
        /// </value>
        [ResizeEffect(Width = 400)]
        public Image SmallSlide { get; set; }
    }
}