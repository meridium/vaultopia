using System.ComponentModel.DataAnnotations;
using System.Linq;
using EPiServer.DataAbstraction;
using EPiServer.DataAnnotations;
using EPiServer.Web;
using ImageVault.Client;
using ImageVault.Common.Data;

namespace Vaultopia.Web.Models.Pages {
    [ContentType(DisplayName = "Gallery", GUID = "f8b2c441-9e8c-4173-9d47-559e8c2a2fe9", Description = "")]
    public class GalleryPage : SitePageData {

        private readonly Client _client = ClientFactory.GetSdkClient();

        /// <summary>
        /// Gets or sets the heading.
        /// </summary>
        /// <value>
        /// The heading.
        /// </value>
        [CultureSpecific]
        [Required]
        [Display(Name = "Heading", GroupName = SystemTabNames.Content, Order = 1)]
        public virtual string Heading { get; set; }

        /// <summary>
        /// Gets or sets the introduction.
        /// </summary>
        /// <value>
        /// The introduction.
        /// </value>
        [CultureSpecific]
        [Display(Name = "Introduction", GroupName = SystemTabNames.Content, Order = 2)]
        [UIHint(UIHint.Textarea)]
        public virtual string Introduction { get; set; }

        /// <summary>
        /// Gets or sets the vault picker.
        /// </summary>
        /// <value>
        /// The vault picker.
        /// </value>
        [UIHint("VaultPicker")]
        [Display(Name = "VaultPicker", Description = "List of available ImageVault vaults", GroupName = SystemTabNames.Content, Order = 3)]
        public virtual string VaultPicker { get; set; }

        #region public override void SetDefaultValues(ContentType contentType)
        /// <summary>
        /// Override Set defaults to set the first vault as selected in the Vaultpicker list
        /// 
        /// Todo: Remove this once the bug "hidden option" -bug has been fixed by EPiServer
        /// </summary>
        /// <param name="contentType"></param>
        public override void SetDefaultValues(ContentType contentType)
        {
            base.SetDefaultValues(contentType);

            VaultPicker = _client.Query<Vault>().OrderBy(v => v.Name).Single().Id.ToString();
        }
        #endregion

    }
}