using System;
using System.Collections.Generic;
using System.Linq;
using EPiServer.Shell.ObjectEditing;
using ImageVault.Client;
using ImageVault.Common.Data;

namespace Vaultopia.Web.Models.Properties.VaultPicker {
    public class VaultPickerSelectionFactory : ISelectionFactory {
        private readonly Client _client;

        /// <summary>
        ///     Initializes a new instance of the <see cref="VaultPickerSelectionFactory" /> class.
        /// </summary>
        public VaultPickerSelectionFactory() {
            _client = ClientFactory.GetSdkClient();
        }

        /// <summary>
        ///     Gets the selections.
        /// </summary>
        /// <param name="metadata">The metadata.</param>
        /// <returns></returns>
        public IEnumerable<ISelectItem> GetSelections(ExtendedMetadata metadata) {
            var vaultList = new List<SelectItem>();

            try {
                var vaults = _client.Query<Vault>().ToList().OrderBy(v => v.Name);

                foreach (var vault in vaults) {
                    vaultList.Add(new SelectItem {Text = vault.Name, Value = vault.Id});
                }
            }
            catch (Exception) {
                // leave the list empty if ImageVault query goes wrong
            }

            return vaultList;
        }
    }
}