define([
//dojo
        "dojo/_base/declare",
        "dojo/_base/lang",
        "dojo/dom",
        "dojo/dom-attr",
        "dojo/sniff",
        "dojo/_base/event",
//dijit
        "dijit/_Widget",
        "dijit/_TemplatedMixin",
        "dijit/_WidgetsInTemplateMixin",
        "dijit/form/TextBox",
        "dijit/focus",
//epi
        "epi/epi",
        "epi/dependency",
//ProcessMap
        "processmap/RequireModule!ProcessMap"
    ], function (
    // dojo
        declare,
        lang,
        dom,
        domAttr,
        sniff,
        event,
    // dijit
        _Widget,
        _TemplatedMixin,
        _WidgetsInTemplateMixin,
        TextBox,
        focusUtil,
    //epi
        epi,
        dependency,
    //ProcessMap
        appModule
) {

    return declare([_Widget, _TemplatedMixin, _WidgetsInTemplateMixin], {
        // templateString: [protected] String
        // A string that represents the default widget template.
        templateString: '<div class="dijitInline">' +
            '<button data-dojo-attach-point="editProcessMapButton" type="button" data-dojo-attach-event="onclick:_openProcessMap">${editButtonString}</button>' +
            '<button data-dojo-attach-point="deleteProcessMapButton" type="button" data-dojo-attach-event="onclick:_deleteProcessMap">${deleteButtonString}</button>' +
            '<input type="hidden" data-dojo-attach-point="hiddenField" data-dojo-type="dijit/form/TextBox"/>' +
            '</div>',
        // The string used as text on the edit button
        editButtonString: null,
        // deleteButtonString: String
        // The string used as text on the delete button
        deleteButtonString: null,
        // the path to ProcessMap Xml Data
        processMapXmlDataPath: null,
        // the ProcessMap URL
        url: null,
        // PageID
        epiPageId: null,
        // Parent PageID
        epiParentPageId: null,
        // FolderID
        epiFolderId: null,
        // Vertical line setting
        verticalLine: null,
        // Horizontal line setting
        horizontalLine: null,
        // the confirm message to display when deleting a ProcessMap
        deleteConfirmMessage: null,
        // postCreate:
        // 
        postCreate: function () {
            // Set up the store
            if (!this.store) {
                var registry = dependency.resolve("epi.storeregistry");
                this.store = registry.get("processmap.dataservicestore");
            }

            if (this.readOnly) {
                this.editProcessMapButton.disabled = true;
                this.deleteProcessMapButton.disabled = true;
            }

        },
        // Gets the XML filename from the ProcessMap URL
        getFileNameFromUrl: function (url) {
            var start = url.indexOf("itemName=") + 9;
            var tempString = url.substring(start);
            var end = tempString.indexOf("&");
            return tempString.substring(0, end);
        },
        // Setter for value property
        _setValueAttr: function (value) {
            this._setValue(value);
        },
        // getOldIdentifier:
        // 
        getOldIdentifier: function () {
            var identifier = this.hiddenField.value == null ? "" : this.hiddenField.value;
            var index = identifier.indexOf("|");

            if (index !== -1) {
                identifier = identifier.substring(0, index);
            }

            return identifier;
        },
        // _openProcessMap:
        // opens ProcessMap
        _openProcessMap: function (e) {
            if (this.readOnly) {
                return;
            }
                
            var oldIdentifier = this.getOldIdentifier();

            // send oldIdentifier to store and retrieve url
            dojo.when(this.store.query({
                oldIdentifier: oldIdentifier, pageId: this.epiPageId, parentPageId: this.epiParentPageId,
                folderId: this.epiFolderId, vertLine: this.verticalLine, horizLine: this.horizontalLine
            }), lang.hitch(this, function (storeResponse) {
                this.url = storeResponse;
                this.newIdentifier = this.getFileNameFromUrl(storeResponse);
                var popupName = "ProcessMap";

                var w = window.open(this.url, popupName, "directories=no,titlebar=no,toolbar=no,location=no,status=no,menubar=no,scrollbars=no,resizable=no,width=10,height=10", true);

                // close the popup once ProcessMap has been launched
                // and if the popup is still open
                // to avoid multiple windows/multiple clickonce launches with addons
                if (w) {
                    w.onload = function () {
                        setTimeout(function () {
                            w.close();
                        }, 500);
                    }; 
                }
                    
                this._setValue(this.newIdentifier);

                // force de-focus to autosave
                focusUtil.curNode && focusUtil.curNode.blur();
            }));

            event.stop(e);
        },
        // _deleteProcessMap:
        // Clears the ProcessMap by setting an empty value
        _deleteProcessMap: function (e) {
            if (this.readOnly) {
                return;
            }

            var clear = confirm(this.deleteConfirmMessage);
            if (clear) {
                this.newIdentifier = null;
                this._setValue(this.newIdentifier);
            }

            event.stop(e);
        },
        //isValid:
        isValid: function () {
            return !this.required || this.value && this.value != "";
        },
        // setter for readOnly
        _setReadOnlyAttr: function (value) {
            this._set("readOnly", value);
        },
        // calling onChange allows for autosave triggering without requiring a mouse click
        onChange: function (value) { },
        // Sets the value of the property
        _setValue: function (value) {
            var jObj = value;
            var filename = value;

            // set empty string if null
            // and toggle enable/dsiabled on the delete button
            if (value === null || typeof (value) === "undefined") {
                jObj = null;
                filename = "";
            } else if (typeof (value) === "string") {

                if (value[0] == '{') {
                    jObj = JSON.parse(value);
                    filename = jObj.Filename ? jObj.Filename : jObj.filename;
                } else {
                    jObj = { 'Filename': value };
                }

            } else if (typeof (value) === "object") {
                filename = value.Filename ? value.Filename : value.filename;
            }

            if (!filename || filename == "") {
                domAttr.set(this.deleteProcessMapButton, "disabled", true);
            } else {
                domAttr.remove(this.deleteProcessMapButton, "disabled");
            }

            this.hiddenField.set("value", filename);
            this.value = jObj;
            this.onChange(jObj);
        }
    });
});
