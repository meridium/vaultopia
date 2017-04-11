define([
// Dojo
    "dojo",
    "dojo/_base/declare",
//CMS
    "epi/_Module",
    "epi/dependency",
    "epi/routes"
], function (
// Dojo
    dojo,
    declare,
//CMS
    _Module,
    dependency,
    routes
) {

    return declare([_Module], {
        // summary: Module initializer for the default module.

        initialize: function () {

            this.inherited(arguments);

            var registry = this.resolveDependency("epi.storeregistry");

            //Register the store
            registry.create("processmap.dataservicestore", this._getRestPath("processmapdataservicestore"));
            //            registry.create("imagevault.browserstore", this._getRestPath("imagevaultbrowserstore"));
            //            registry.create("imagevault.mediaitemstore", this._getRestPath("imagevaultmediaitemstore"));
            //            registry.create("imagevault.propertymediacommonsettingsstore", this._getRestPath("imagevaultpropertymediacommonsettingsstore"));
            //            registry.create("imagevault.categorystore", this._getRestPath("imagevaultcategorystore"));

            //HACK, the avatar class is just a copy of EPiServers Avatar but with the posibility to fully customize the avatar creation.
            // DnD manager customizations (overrides the customizations made in epi/shell/ShellModule)
            //            var manager = dndManager.manager();
            //            manager.makeAvatar = function () {
            //                return new Avatar(this);
            //            };
        },

        _getRestPath: function (name) {
            return routes.getRestPath({ moduleArea: "ProcessMap", storeName: name });
        }
    });
});
