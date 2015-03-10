(function ($, ns) {
	/**
	* Base class for buttons
	*/
	var buttonBase = function () {
	};
	buttonBase.prototype = {
		//properties
		//reference to the TinyMCE editor
		editor: null,
		//base url of the site
		siteUrl: null,
		//title of the button
		title: null,
		//image of the button
		image: null,
		//the spinner instance
		spinner: null,
		//Used to store the selected node in the "editor", since selection is lost in IE when crop/zoom is opened
		SelectedNode: null,
		//Methods
		//adds the command and button and binds it to the supplied callback
		addButtonAndRegisterCommand: function (callback) {
			//add command
			this.editor.addCommand(this.command, function () {
				callback();
			});
			//add button
			this.editor.addButton(this.id, { title: this.title, image: this.image, cmd: this.command });
		},
		//cited from http://thudjs.tumblr.com/post/637855087/stylesheet-onload-or-lack-thereof
		loadStyleSheet: function (path, fn, scope) {
			var head = document.getElementsByTagName('head')[0]; // reference to document.head for appending/ removing link nodes
			var link = document.createElement('link');           // create the link node
			link.setAttribute('href', path);
			link.setAttribute('rel', 'stylesheet');
			link.setAttribute('type', 'text/css');

			var sheet, cssRules;
			// get the correct properties to check for depending on the browser
			if ('sheet' in link) {
				sheet = 'sheet'; cssRules = 'cssRules';
			} else {
				sheet = 'styleSheet'; cssRules = 'rules';
			}

			var intervalId = setInterval(function () { // start checking whether the style sheet has successfully loaded
				try {
					if (link[sheet] && link[sheet][cssRules].length) { // SUCCESS! our style sheet has loaded
						clearInterval(intervalId); // clear the counters
						clearTimeout(timeoutId);
						fn.call(scope || window, true, link); // fire the callback with success == true
					}
				} catch (e) {
				} finally {
				}
			}, 10);                               // how often to check if the stylesheet is loaded
			var timeoutId = setTimeout(function () {       // start counting down till fail
				clearInterval(intervalId);             // clear the counters
				clearTimeout(timeoutId);
				head.removeChild(link);                // since the style sheet didn't load, remove the link node from the DOM
				fn.call(scope || window, false, link); // fire the callback with success == false
			}, 15000);                                 // how long to wait before failing

			head.appendChild(link);  // insert the link node into the DOM and start loading the style sheet

			return link; // return the link node;
		},
		//asserts that a script is loaded. If not it tries to load the supplied script url
		//when loading has been verified, the loadedCallback is called
		//scriptUrl: url of script to load
		//verifyIsLoadedCallback: function that returns true if the verification that the script is loaded. false if the script is not found
		//loadedCallback: called when verifyIsLoadedCallback returns true.
		_scriptLoaderCallbacks: {},
		loadScript: function (scriptUrl, verifyIsLoadedCallback, loadedCallback, scope) {
			var self = this;
			if (!verifyIsLoadedCallback()) {
				//if we haven't tried to load the script before, create the callback
				if (!this._scriptLoaderCallbacks[scriptUrl]) {
					this._scriptLoaderCallbacks[scriptUrl] = function () {
						loadedCallback.call(scope || window, true);
					};
					//if we already has tried to load the script (but not completed loading it), add new callback to the list
				} else {
					var fn = this._scriptLoaderCallbacks[scriptUrl];
					this._scriptLoaderCallbacks[scriptUrl] = function () {
						fn();
						loadedCallback.call(scope || window, true);
					};
					return;
				}
				// Load a script using a unique instance of the script loader
				var scriptLoader = new tinymce.dom.ScriptLoader();
				scriptLoader.load(scriptUrl);
				scriptLoader.loadQueue(function () {
					if (!verifyIsLoadedCallback()) {
						throw "Failed verify that script is loaded " + scriptUrl;
					}
					var fn2 = self._scriptLoaderCallbacks[scriptUrl];
					//mark script as loaded
					self._scriptLoaderCallbacks[scriptUrl] = null;
					//run callback
					fn2();

					//					loadedCallback.call(scope || window, true);
				});
			} else {
				loadedCallback.call(scope || window, false);
			}
		},
		//loads the json script if it isn't already loaded
		loadJSON: function (callback, scope) {
			var isJsonLoaded = function () { try { return JSON && JSON.stringify && JSON.parse; } catch (e) { return false; } };
			this.loadScript(this.editor.settings.imagevault_imageVaultEPiServerCmsBaseUrl + "Scripts/JSON2.js", isJsonLoaded, function () {
				callback.call(scope || window);
			}, this);
		},
		_loadjQuerySession: {
			noOfRequest: 0,
			oldjQuery: null,
			old$: null
		},
		//loads the jquery script if it isn't already loaded
		//the supplied callback takes one argument and that is another callback that should be called when the jquery should be released from the global scope.
		loadjQuery: function (callback, scope) {
			var self = this;
			var isJquery161Loaded = function () { return (jQuery && jQuery.fn.jquery == "1.6.1") || (window.iv_jQuery && window.iv_jQuery.fn.jquery == "1.6.1"); };
			this.loadJSON(function () {
				this.loadScript(this.editor.settings.imagevault_imageVaultEPiServerCmsBaseUrl + "Scripts/jquery-1.6.1.min.js", isJquery161Loaded, function (loaded) {
					this._loadjQuerySession.noOfRequest++;

					//if this is the first request
					if (this._loadjQuerySession.noOfRequest == 1) {
						//if we didn't load jQuery, it's already loaded and we have it registered as window.iv_jQuery
						if (!loaded) {
							if (typeof window.iv_jQuery === "undefined" || !window.iv_jQuery)
								window.iv_jQuery = window.jQuery;
							if (window.iv_jQuery.fn.jquery != "1.6.1")
								throw "Wrong version of jQuery found as window.iv_jQuery, Expected 1.6.1, actual " + window.iv_jQuery.fn.jquery;

							//store current jQuery
							this._loadjQuerySession.oldjQuery = window.jQuery;
							this._loadjQuerySession.old$ = window.$;
							window.jQuery = window.$ = window.iv_jQuery;
						}
					}

					callback.call(scope || window, function () {
						self._loadjQuerySession.noOfRequest--;
						//if this was the last request
						if (self._loadjQuerySession.noOfRequest == 0) {
							if (loaded) {
								//when we load jquery, we need to store it in the iv_jQuery variable (that ImageVault.Client tries to use)
								//we call the noconflict to restore previous version of jquery
								window.iv_jQuery = jQuery.noConflict(true);
							} else {
								//update iv_jQuery with installed modules
								window.iv_jQuery = window.jQuery;
								//restore current values
								window.jQuery = self._loadjQuerySession.oldjQuery;
								window.$ = self._loadjQuerySession.old$;
							}
						}
					});
				}, this);
			}, this);
		},
		loadSpinner: function (callback, scope) {
			this.loadjQuery(function (disposejQueryCallback) {
				var isSpinnerLoaded = function () { return typeof Spinner === "function"; };
				this.loadScript(this.editor.settings.imagevault_imageVaultEPiServerCmsBaseUrl + "Scripts/spin-min.js", isSpinnerLoaded, function () {
					disposejQueryCallback();
					callback.call(scope || window);
				});
			}, this);
		},
		//loads the client script if it isn't already loaded
		loadClient: function (callback, scope) {
			var isIvClientLoaded = function () { return window.ImageVault && window.ImageVault.Client; };

			this.loadjQuery(function (disposejQueryCallback) {
			    this.loadScript(this.editor.settings.imagevault_imageVaultEPiServerCmsBaseUrl + "Scripts/ImageVault.Client.js", isIvClientLoaded, function () {
					disposejQueryCallback();
					callback.call(scope || window);
				}, this);
			}, this);
		},
		//loads the PropertyMediaCommon script
		loadPropertyMediaCommon: function (callback, scope) {
			var isPropertyMediaCommonLoaded = function () { return ImageVault && ImageVault.PropertyMediaCommon; };
			//requires jQuery
			this.loadFancyBox(function (disposejQueryCallback) {
				this.loadScript(this.editor.settings.imagevault_imageVaultEPiServerCmsBaseUrl + "Scripts/ImageVault.PropertyMediaCommon.js", isPropertyMediaCommonLoaded, function (loaded) {
					disposejQueryCallback();
					if (loaded) {
						//setup PropertyMediaCommon globals (if missing)
						if (!ImageVault.PropertyMediaCommon.ivUiAuthUrl)
							ImageVault.PropertyMediaCommon.ivUiAuthUrl = this.editor.settings.imagevault_ivUiAuthUrl;
						if (!ImageVault.PropertyMediaCommon.editorUri)
							ImageVault.PropertyMediaCommon.editorUri = this.editor.settings.imagevault_editorUri;
						if (!ImageVault.PropertyMediaCommon.mediaUrlBase)
							ImageVault.PropertyMediaCommon.mediaUrlBase = this.editor.settings.imagevault_mediaUrlBase;
						if (!ImageVault.PropertyMediaCommon.msg) {
							ImageVault.PropertyMediaCommon.msg = {
								editorWidthInputLabel: this.editor.settings.imagevault_pmcm_editorWidthInputLabel,
								editorHeightInputLabel: this.editor.settings.imagevault_pmcm_editorHeightInputLabel,
								editorOkButtonText: this.editor.settings.imagevault_pmcm_editorOkButtonText,
								editorCancelButtonText: this.editor.settings.imagevault_pmcm_editorCancelButtonText,
								editorWarningIconText: this.editor.settings.imagevault_pmcm_editorWarningIconText,
								editorReloadButtonText: this.editor.settings.imagevault_pmcm_editorReloadButtonText
							};
						}
					}
					callback.call(scope || window);
				}, this);
				//signal to fancybox that it will handle disposing by itself (we must wait until pmc has loaded)
				return true;
			}, this);
		},
		//the callback function can take a dispose callback as parameter. if dispose of jquery should be handled by the callback, the 
		//callback must return true otherwize the loadFancyBox will dispose the jQuery object as soon as the callback returns
		loadFancyBox: function (callback, scope) {
			//requires jQuery
			this.loadjQuery(function (disposejQueryCallback) {
				//if ie, don't load fancybox, we use a popup instead
				if ($.browser.msie) {
					//dispose if not callback volunteers to
					if (!callback.call(scope || window, disposejQueryCallback)) {
						disposejQueryCallback();
					}
					return;
				}
				//either it is loaded into the iv_jQuery (already loaded) or when loading (before restoring iv_jQuery) it will be found in jQuery variable
				var isFancyBoxLoaded = function () { return window.iv_jQuery.fn.fancybox || window.jQuery.fn.fancybox; };
				this.loadScript(this.editor.settings.imagevault_imageVaultEPiServerCmsBaseUrl + "Scripts/jquery.fancybox-1.3.4.pack.js", isFancyBoxLoaded, function (loaded) {
					if (loaded) {
						//load css too
						this.loadStyleSheet(this.editor.settings.imagevault_imageVaultEPiServerCmsBaseUrl + "Styles/jquery.fancybox-1.3.4.css", function () {
							//dispose if not callback volunteers to
							if (!callback.call(scope || window, disposejQueryCallback)) {
								disposejQueryCallback();
							}
						});
					} else {
						//dispose if not callback volunteers to
						if (!callback.call(scope || window, disposejQueryCallback)) {
							disposejQueryCallback();
						}
					}
					//dispose if not done
				}, this);
			}, this);

		},
		//Gets the client for communicating with core
		getClient: function (callback, scope) {
			this.loadClient(function () {
				//Create client instance (if not already existing)
				if (!ImageVault.Client.Instance) {
					ImageVault.Client.Instance = new ImageVault.Client({
					    core: this.editor.settings.imagevault_ivCoreProxy,
                        authMethod: "none"
					});
				}

				//then call the callback
				callback.call(scope || window, ImageVault.Client.Instance);
			}, this);
		},

		//checks if the supplied url is a imagevault url
		isImageVaultUrl: function (url) {
			if (/\/media\/[a-z,0-9]{20}\//i.test(url))
				return true;
			if (/\/publishedmedia\/[a-z,0-9]{20}\//i.test(url))
				return true;
			return false;
		},
		showSpinner: function ($elem) {
			this.loadSpinner(function () {
				if (this.spinner)
					this.hideSpinner();
				var opts = {
					lines: 13, // The number of lines to draw
					length: 8, // The length of each line
					width: 3, // The line thickness
					radius: 10, // The radius of the inner circle
					corners: 1, // Corner roundness (0..1)
					rotate: 0, // The rotation offset
					color: '#222', // #rgb or #rrggbb
					speed: 1, // Rounds per second
					trail: 60, // Afterglow percentage
					shadow: true, // Whether to render a shadow
					hwaccel: true, // Whether to use hardware acceleration
					className: 'spinner', // The CSS class to assign to the spinner
					zIndex: 2e9, // The z-index (defaults to 2000000000)
					top: 'auto', // Top position relative to parent in px
					left: 'auto' // Left position relative to parent in px
				};
				this.spinner = new Spinner(opts).spin($elem.get(0));
			}, this);

		},
		hideSpinner: function () {
			if (this.spinner) {
				this.spinner.stop();
				this.spinner = null;
			}
		},
		//this method is used to insert the selected media into the editor
		//data is the MediaFormatBase instance
		insertMedia: function (data) {
		    var self = this;
		    
			if (this.SelectedNode) this.editor.selection.select(this.SelectedNode); // reset the selection

			//setup the addHtml function
			var addHtml = function (html) {
				self.editor.execCommand('mceInsertContent', false, html);

				// Let TinyMCE know the window is closed
				self.editor.windowManager.onClose.dispatch();
			};
			//if we selected an image, replace it
			if (this.editor.selection.getNode().nodeName.toUpperCase() == "IMG") {

				addHtml = function (html) {
					self.editor.execCommand('mceReplaceContent', false, html);
					//mceRepaint added for removing the selection and handles in firefox/IE
					self.editor.execCommand('mceRepaint');

					// Let TinyMCE know the window is closed
					self.editor.windowManager.onClose.dispatch();
				};
			}
			var media = this.parseOriginalAndMedia(data);
			var ret = media.SelectedMedia;
			//if the content supplies a player, use that Html instead
			if (ret.ContentDisplayType == 1) {
				addHtml(ret.Html);
				return;
			}
			var url = ret.Url;
			addHtml('<img src="' + url + '"/>');

			return;

		},
		//parses the supplied mediaItem and identifies the original media and the selected media
		//returns {OriginalMedia, SelectedMedia}
		parseOriginalAndMedia: function (mediaItem) {
			var originalMedia = null, selectedMedia = null;
			//no data
			if (!mediaItem || !mediaItem.MediaConversions || !mediaItem.MediaConversions.length)
				return null;
			//is first original?
			if (this.isOriginalImageFormat(mediaItem.MediaConversions[0])) {
				originalMedia = mediaItem.MediaConversions[0];
				if (mediaItem.MediaConversions.length > 1)
					selectedMedia = mediaItem.MediaConversions[1];
				//is second original or do we only have one format?
			} else if (mediaItem.MediaConversions.length == 1 || this.isOriginalImageFormat(mediaItem.MediaConversions[1])) {
				if (mediaItem.MediaConversions.length > 1)
					originalMedia = mediaItem.MediaConversions[1];
				selectedMedia = mediaItem.MediaConversions[0];
			} else {
				return null;
			}
			//if original is inserted, use original as selectedMedia
			if (!selectedMedia)
				selectedMedia = originalMedia;

			return { OriginalMedia: originalMedia, SelectedMedia: selectedMedia };
		},
		isOriginalImageFormat: function (media) {
			//original format needs to be called Original
		//	if (media.MediaFormatName != "Original")
		//		return false;
			//it cannot have any dimensions set
			if (media.FormatWidth || media.FormatHeight || media.FormatAspectRatio || (media.Effects && media.Effects.length))
				return false;
			return true;
		}

	};
	/**
	* Button class represents data and code for using the imagevault tinymce button
	*/
	var addButton = function (config) {
		this.init(config);
	};
	//copy base methods
	$.extend(addButton.prototype, buttonBase.prototype);
	$.extend(addButton.prototype, {
		//the command of the button
		command: 'openImageVault',
		//id of control in TinyMce
		id: 'imagevaultButton',

		//init function, setup variables 
		init: function (config) {
			$.extend(this, config);
			var self = this;
			this.editor.onNodeChange.add(function (editor, cm, n) { self.nodeChanged(editor, cm, n); });
		    this.addButtonAndRegisterCommand(function() { self.openImageVault(); });
		},
		nodeChanged: function (ed, cm, n) {
			var isImageVaultImage = false;
			n = ed.selection.getNode();
			if (n && n.nodeName && n.nodeName.toLowerCase() == "img") {
				isImageVaultImage = this.isImageVaultUrl(n.src);
			}
			cm.setActive(this.id, isImageVaultImage);
		},
		//opens imagevault (makes sure that the uicallback script is loaded)
		openImageVault: function () {
			var self = this;

			// Dispatch event to let TinyMCE know a new window is opening
			// This helps EPi autosave trigger after insert
			self.editor.windowManager.onOpen.dispatch();

			this.loadScript(this.editor.settings.imagevault_imageVaultEPiServerCmsBaseUrl + "Scripts/ImageVault.UICallback.js",
				function () { return window.ImageVault && window.ImageVault.UiCallback && window.ImageVault.UiCallback.Instance; },
				function () { self.openImageVaultWhenScriptIsLoaded(); }
			);
		},
		_getWindowName: function (name) {
			//IE don't handle window names with - in them
			name = (name || "noname").replace(new RegExp("-", "g"), '_');
			return name;
		},
		//Real open ImageVault function. Only works if UiCallback script is loaded
		openImageVaultWhenScriptIsLoaded: function () {
			var params = '?PageLang=' + this.editor.settings.epi_page_context.epslanguage;
			params += '&UiLang=' + this.editor.getLang('imagevault.language', "en");
			params += '&insertMultiple=false&FormatId=NA';
			params += '&EnsurePublishingSource=' + encodeURIComponent(this.editor.settings.imagevault_publishIdentifier);
			params += '&MediaUrlBase=' + encodeURIComponent(this.editor.settings.imagevault_mediaUrlBase);
			var openIvForInsertUrl = this.editor.settings.imagevault_imageVaultUiBaseUrl;
		    //if ui is external, open a local page first (iframe needed by ie for postMessage to work)
            if (this.editor.settings.imagevault_imageVaultUiIsExternal) {
                params += "&u=" + encodeURIComponent(openIvForInsertUrl);
                openIvForInsertUrl = this.editor.settings.imagevault_imageVaultEPiServerCmsBaseUrl + "scripts/ivui.aspx";
            }
			//when opening a window with windowManager.open the name of the window is empty.
            var url = openIvForInsertUrl + params;
			var name = this._getWindowName("fritext" + this.editor.id);
			var self = this;
			//register window as an opener
			ImageVault.UiCallback.Instance.RegisterOpener(name, false, function (data) {
				self.insertMedia(data);
			});
			window.open(url, name, 'width=1034,height=768,resizable=yes,scrollbars');
		}
	});
	ns.TinyMceAddButton = addButton;

	/**
	* Button class for Edit
	*/
	var editButton = function (config) {
		this.init(config);
	};
	//copy base methods
	$.extend(editButton.prototype, buttonBase.prototype);

	$.extend(editButton.prototype, {
		//the command of the button
		command: 'openImageVaultEditor',
		//id of control in TinyMce
		id: 'imagevaultEditorButton',

		//init function, setup variables 
		init: function (config) {
			$.extend(this, config);
			var self = this;
			this.editor.onNodeChange.add(function (editor, cm, n) { self.nodeChanged(editor, cm, n); });
			this.addButtonAndRegisterCommand(function () { self.openEditor(); });

		},
		nodeChanged: function (ed, cm, n) {
			var isImageVaultImage = false;
			n = ed.selection.getNode();
			if (n && n.nodeName && n.nodeName.toLowerCase() == "img") {
				isImageVaultImage = this.isImageVaultUrl(n.src);
			}
			cm.setActive(this.id, isImageVaultImage);
			cm.setDisabled(this.id, !isImageVaultImage);

		},

		openEditor: function () {
			var self = this;
			var node = this.editor.selection.getNode();
			if (!node || !node.src) {
				alert("No image selected");
				return;
			}
            this.SelectedNode = node; // Store the selected node
		    
			// Dispatch event to let TinyMCE know a new window is opening
			// This helps EPi autosave trigger after edit
			self.editor.windowManager.onOpen.dispatch();

			//display the spinner centered over the editor "edit pane" (the table cell)
			this.showSpinner($(this.editor.getContainer()).find(".mceIframeContainer"));
			this.getClient(function (client) {
				var parameters = {
					Filter: { Url: [node.src] },
					Populate: {
						MediaFormats: [{ $type: "ImageVault.Common.Data.ImageFormat,ImageVault.Common"}]
					},
					MediaUrlBase: self.editor.settings.imagevault_mediaUrlBase
				};

				//we stringify the parameters first before passing to the client
				//the client resides in the parent window and for IE that means passing arrays over windows makes them to objects (assocciative arrays)
				//thus the json gets all mixed up.
				var json = JSON.stringify(parameters);
				client.json("MediaService/Find", json, function (x) {
					//					alert(JSON.stringify(x));
					if (!x || x.length != 1) {
						//check if this was a server error
						var err = client.getLastErrorMessage();
						if (err) {
							if (/no access/i.test(err))
								alert(self.editor.settings.imagevault_pmcm_editorDisabledNoAccessToMedia);
							else
								alert("Error finding media. " + err);
						} else {
							alert("Cannot find image in ImageVault. It's either removed or you don't have access.");
						}
						self.hideSpinner();
						return;
					}
					var mediaItem = x[0];

					self.loadPropertyMediaCommon(function () {
						var pmc = new ImageVault.PropertyMediaCommon();
						//add method for storing effects from editor
						//this method will be called when the editing is completed
						//async programming is never easy to read ;)
						pmc.storeEffects = function (effects) {
							//alert(JSON.stringify(effects));

							self.showSpinner($(self.editor.getContainer()).find(".mceIframeContainer"));
							var editedMediaReference = {
								Id: mediaItem.Id,
								Effects: effects
							};
							pmc.getMedia(editedMediaReference, function (editedMediaItem) {
								if (editedMediaItem === null) {
									alert("Error getting media. " + pmc.getClient().getLastErrorMessage());
								} else {
									self.insertMedia(editedMediaItem);
								}
								self.hideSpinner();
							});
						};

						//continue with normal processing... ;)
						//calculate which one is original...
						var media = self.parseOriginalAndMedia(mediaItem);
						if (!media) {
							self.hideSpinner();
							throw "Cannot find original format " + json.stringify(mediaItem);
						}

						//Check if ContentType isn't a image
						if (!/^image\//i.test(media.OriginalMedia.ContentType)) {
							self.hideSpinner();
							alert(self.editor.settings.imagevault_pmcm_editorDisabledOriginalFormatNotSupported);
							return;
						}

						//get effect from format 
						self.getEffectsFromFormat(media.SelectedMedia.MediaFormatId, media.OriginalMedia, function (effects) {
							var mediaCache = { Original: media.OriginalMedia };
							var mediaReference = {
								Id: mediaItem.Id,
								Effects: effects
							};
							//make sure fancybox is loaded and open the editor.
							self.loadFancyBox(function () {
								pmc.spinner = self.spinner;
								self.spinner = null;
								pmc.openEditor(mediaCache, mediaReference);
							});
						});
					});
				});
			});
		},
		getEffectsFromFormat: function (formatId, orgFormat, callback) {
			var self = this;
			this.getClient(function (client) {
				var parameters = {
					Filter: { Format: { Id: formatId} }
				};
				var json = JSON.stringify(parameters);
				client.json("MediaFormatService/Find", json, function (x) {
					if (x && x.length) {
						callback(self.convertFormatToEffects(x[0], orgFormat));
					} else {
						alert("Error getting format from server. " + client.getLastErrorMessage());
					}
				});
			});
		},
		convertFormatToEffects: function (format, orgMedia) {
			var effects = format.Effects || [];
			var w = format.Width;
			var h = format.Height;
			var a = format.AspectRatio;
			var ow = orgMedia.Width;
			var oh = orgMedia.Height;
			var oa = ow / oh;

			//CROP?
			//if we have an aspect ratio and it differs from the original, and the original dimension is greater than the format, on one side atleast, issue a crop
			if (a && a != oa && (ow > w || oh > h)) {

				//Which dimension to crop
				var aw = a * oh;
				var ah = ow / a;
				var cx = 0, cy = 0, cw, ch;
				//if we are wider than aspect ratio, crop sides
				if (ow > aw) {
					//if original is smaller than format, don't use the aspect ratio. Get most out of the image
					if (oh < h) {
						ch = oh;
						cw = w;
					} else {
						cw = aw;
						ch = oh;
					}
					cx = Math.round((ow - cw) / 2);
				} else {
					//crop top bottom
					//if original is smaller than format, don't use the aspect ratio. Get most out of the image
					if (ow < w) {
						cw = ow;
						ch = h;
					} else {
						ch = ah;
						cw = ow;
					}
					cy = Math.round((oh - ch) / 2);
				}
				effects.push({ $type: "ImageVault.Common.Data.Effects.CropEffect,ImageVault.Common", X: cx, Y: cy, Width: cw, Height: ch });
				//if size is smaller or equal to format, don't resize.
				if (cw <= w && ch <= h)
					return effects;
			}

			//RESIZE?

			//we only do resize if width or height is supplied and is smaller than original
			if ((w && w < ow) || (h && h < oh))
				effects.push({ $type: "ImageVault.Common.Data.Effects.ResizeEffect,ImageVault.Common", Width: w || 0, Height: h || 0 });
			return effects;
		}

	});
	ns.TinyMceOpenEditorButton = editButton;

	tinymce.create('tinymce.plugins.ImageVaultPlugin', {
		//properties

		//methods
		init: function (ed, url) {

			//change the settings so the iframes can be added
			if (ed.settings.extended_valid_elements.indexOf("iframe[") < 0) {
				ed.settings.extended_valid_elements = ed.settings.extended_valid_elements + ",iframe[src|width|height|frameborder|name|title|allowfullscreen]";
			}

			var siteUrl = url.toLowerCase().replace('/util/editor/tinymce/plugins/imagevault', '');
			var baseConfig = {
				editor: ed,
				siteUrl: siteUrl
			};
			//create button class
			var openIvButton = new ImageVault.TinyMceAddButton($.extend({
				title: 'ImageVault',
				image: url + '/ImageVaultEditorPlugin.png'
			}, baseConfig));
			var openEditorButton = new ImageVault.TinyMceOpenEditorButton($.extend({
				title: 'ImageVault Editor',
				image: url + '/ImageVaultEditorButton.png'
			}, baseConfig));
		    
		    //make sure that JSON is loaded
		    openIvButton.loadJSON(function(){});

		},
		/**
		* Returns information about the plugin as a name/value array.
		* The current keys are longname, author, authorurl, infourl and version.
		*
		* @return {Object} Name/value array containing information about the plugin.
		*/
		getInfo: function () {
			return {
				longname: 'ImageVault TinyMCE plugin',
				author: 'Meriworks',
				authorurl: 'http://www.imagevault.se',
				infourl: 'http://www.imagevault.se',
				version: "4.0"
			};
		}
	});
	tinymce.PluginManager.add('imagevault', tinymce.plugins.ImageVaultPlugin);
})(jQuery, window.ImageVault != null ? window.ImageVault : window.ImageVault = {});

