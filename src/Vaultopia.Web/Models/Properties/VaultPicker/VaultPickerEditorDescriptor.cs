using System;
using System.Collections.Generic;
using EPiServer.Shell.ObjectEditing.EditorDescriptors;

namespace Vaultopia.Web.Models.Properties.VaultPicker
{
    [EditorDescriptorRegistration(TargetType = typeof(string), UIHint = "VaultPicker")]
    public class VaultPickerEditorDescriptor : EditorDescriptor
    {
        public override void ModifyMetadata(EPiServer.Shell.ObjectEditing.ExtendedMetadata metadata, IEnumerable<Attribute> attributes) {
            SelectionFactoryType = typeof (VaultPickerSelectionFactory);
            ClientEditingClass = "epi.cms.contentediting.editors.SelectionEditor";

            base.ModifyMetadata(metadata, attributes);
        }
    }
}