using System;
using System.Collections.Generic;
using EPiServer.Shell.ObjectEditing;
using EPiServer.Shell.ObjectEditing.EditorDescriptors;

namespace Vaultopia.Web.Models.Properties.VaultPicker {
    [EditorDescriptorRegistration(TargetType = typeof (string), UIHint = "VaultPicker")]
    public class VaultPickerEditorDescriptor : EditorDescriptor {
        /// <summary>
        ///     Modifies the metadata.
        /// </summary>
        /// <param name="metadata">The metadata.</param>
        /// <param name="attributes">The attributes.</param>
        public override void ModifyMetadata(ExtendedMetadata metadata, IEnumerable<Attribute> attributes) {
            SelectionFactoryType = typeof (VaultPickerSelectionFactory);
            ClientEditingClass = "epi.cms.contentediting.editors.SelectionEditor";

            base.ModifyMetadata(metadata, attributes);
        }
    }
}