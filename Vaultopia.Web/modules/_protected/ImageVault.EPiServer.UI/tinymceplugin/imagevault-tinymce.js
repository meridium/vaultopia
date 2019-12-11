"use strict";
var tinymce = tinymce || {};


/*
 * TinyMCE plugin for inserting and/or editing media from ImageVault.
 *
 * Opens a child window and then uses the postMessage API to
 * receive the image to insert into the editor.
 *
 * Settings:
 * Settings:
 *  • imageVaultBaseUrl (required) - the base URL to ImageVault (e.g. https://my.imagevault.com), normally this is the imageVaultUiUrl in imagevault.client.config
 *  • defaultMediaUrlBase (optional) - The url base that the media assets should use. Supply the url to a cdn.
 *  • imageVaultPublishDetailsUrl (optional) - if set, returned media will be published by the given URL. If not set, returned media will be private.
 *  • imageVaultPublishDetailsText (optional) - the text describing where media is published
 *  • imageVaultPublishDetailsGroupId (optional) - the group ID of the published media
 *  • useIframeProxy (optional) - if set to true a window with iframe will be used for compability with IE11
 *  • debugLog (optional) - if set to true logs debug messages
 */

tinymce.PluginManager.add('imagevault', function (editor, url) {

    // polyfill Promise if needed
    if (typeof Promise !== 'function') {
        tinymce.ScriptLoader.loadScripts([url + '/lib/es6-promise.min.js'],
            function () {
                window.Promise = ES6Promise;
            });
    }

    // reference to the ImageVault window
    var ivWindow;

    // url to iframe proxy page
    const iframeProxyPage = url + '/imagevault-window.html';

    // url to error page
    const errorPage = url + '/error.html';

    // url to ImageVault button icon
    const imageVaultIcon = url + '/vault_grey.svg';

    // url to edit button icon
    const cropIcon = url + '/crop.svg';

    // true if ImageVault window is open and communication is in progress,
    // false otherwise
    var ivWindowCommunicating = false;

    // features of the ImageVault window
    const ivWindowFeatures = 'width=1034,height=768,resizable=yes,scrollbars';

    // use event when window is closing
    var eventDispatcher = new tinymce.util.EventDispatcher();

    // reference to the ping timeout so we can clear it
    // when window closes
    var pingTimer;

    // polyfill for location.origin
    if (typeof location.origin === 'undefined') {
        location.origin = location.protocol + '//' + location.host;
    }

    // origin of imagevault / iframe proxy
    var targetOrigin;

    const logEnabled = editor.settings.debugLog;

    /*
     * Adds the button to insert ImageVault media and handles
     * the insert action
     */
    editor.addButton('imagevault-insert-media',
        {
            title: 'Insert',
            image: imageVaultIcon,
            tooltip: 'Insert ImageVault media',
            onclick: function () {
                verifyConfig()
                    .then(function() {
                        // Focus tiny (to trigger save and publish events)
                        editor.focus();

                        // Open ImageVault
                        openImageVaultWindow('insert');
                    })
                    .then(waitForWindowToClose)
                    .then(function (media) { addMediaToEditor(media); })
                    .catch(function (error) { handleError(error); });
            }
        });

    /*
     * Adds the button that edits ImageVault media and handles
     * the edit action 
     */
    editor.addButton('imagevault-edit-media',
        {
            title: 'Edit',
            image: cropIcon,
            tooltip: 'Edit selected ImageVault media',
            onclick: function () {
                verifyConfig()
                    .then(function () { openImageVaultWindow('edit'); })
                    .then(waitForWindowToClose)
                    .then(function (media) { addMediaToEditor(media); })
                    .catch(function (error) { handleError(error); });
            },
            onpostrender: monitorNodeChange
        });

    /*
     * Edit button is only enabled when we have
     * an img selected.
     */
    function monitorNodeChange() {
        var btn = this;
        editor.on('NodeChange',
            function (e) {
                btn.disabled(!e.element || !e.element.nodeName || e.element.nodeName.toLowerCase() !== "img");
            });
    }

    /*
     * Verifies all required editor configuration exist
     */
    function verifyConfig() {
        if (!editor.settings.imageVaultBaseUrl) {
            return Promise.reject(Error('Missing required editor configuration: imageVaultBaseUrl'));
        }

        if (editor.settings.useIframeProxy) {
            targetOrigin = location.origin;
        } else {
            targetOrigin = editor.settings.imageVaultBaseUrl;
        }

        // Make sure target origin does not have trailing slash
        if (targetOrigin.slice(-1) === '/') {
            targetOrigin = targetOrigin.slice(0, -1);
        }

        return Promise.resolve();
    }

    /*
     * Opens ImageVault window in 'insert' or 'edit' mode
     */
    function openImageVaultWindow(mode) {
        try {
            const windowUrl = createUrl(mode);
            const windowName = 'IvTinyMce_' + editor.id;

            logEnabled && console.info('Opening window with name: ' + windowName);

            ivWindow = window.open(windowUrl, windowName, ivWindowFeatures);

            if (window.addEventListener) {
                ivWindow.opener.addEventListener('message', messageEvent, false);
            } else if (window.attachEvent) {
                window.attachEvent('onmessage', messageEvent);
            }

            initWindowCommunication();
            return Promise.resolve();
        } catch (e) {
            return Promise.reject(Error('Error opening ImageVault window: ' + e.message));
        }
    }

    /*
     * Waits for event when external window has closed
     */
    function waitForWindowToClose() {
        return new Promise(function (resolve) {
            eventDispatcher.on('ivWinClosed', function (e) {
                eventDispatcher.off('ivWinClosed');
                resolve(e.media);
            });
        });
    }


    /*
     * Handle errors nicely
     */
    function handleError(error) {
        editor.windowManager.open({
            title: 'Error opening ImageVault',
            url: errorPage,
            width: 700,
            height: 400
        },
            {
                errorMessage: error
            });
    }

    /*
     * Create absolute URL with required parameters to insert or edit media
     */
    function createUrl(mode) {
        // common params for all requests
        var params = {
            imageVaultBaseUrl: editor.settings.imageVaultBaseUrl,
            ensurePublishingSource: editor.settings.ensurePublishingSource,
            insertMultiple: 'false',
            formatId: 'NA'
        };

        // add (optional) publish info
        if (editor.settings.imageVaultPublishDetailsUrl) {
            params['publishdetails.Url'] = editor.settings.imageVaultPublishDetailsUrl;

            if (editor.settings.imageVaultPublishDetailsText) {
                params['publishdetails.Text'] = editor.settings.imageVaultPublishDetailsText;
            }

            if (editor.settings.imageVaultPublishDetailsGroupId) {
                params['publishdetails.GroupId'] = editor.settings.imageVaultPublishDetailsGroupId;
            }
        }

        if (editor.settings.defaultMediaUrlBase) {
            params['MediaUrlBase'] = editor.settings.defaultMediaUrlBase;
        }

        if (mode === 'edit') {
            // include mediaUrl for edit
            const selectedImage = tinymce.activeEditor.selection.getNode();

            // src for poster image for video (to edit video)
            const videoSrc = selectedImage.getAttribute("data-mce-p-poster");

            var mediaUrl = "";

            if (videoSrc) {
                mediaUrl = videoSrc;
            } else {
                mediaUrl = selectedImage.getAttribute("src");
            }

            params.mediaUrl = mediaUrl;
        }


        var ivUrl;

        // check if we should call ImageVault directly
        // or use iframe proxy
        if (editor.settings.useIframeProxy) {
            //if we are using new version of iv/use redirectAfterLogin
            if (editor.settings.imageVaultSupportRedirectAfterLogin) {
                params["forceLogin"] = 1;
            }
            ivUrl = iframeProxyPage;
        } else {
            ivUrl = editor.settings.imageVaultBaseUrl;
        }

        const query = Object.keys(params)
            .map(function (k) { return encodeURIComponent(k) + '=' + encodeURIComponent(params[k]); })
            .join('&');

        ivUrl += '?' + query;
        
        logEnabled && console.info('ImageVault URL: ' + ivUrl);
        return ivUrl;
    }

    /*
     * Initiates the window communication, waits for initReceived
     * before accepting data.
     */
    function initWindowCommunication() {
        if (!ivWindowCommunicating && ivWindow.opener) {
            logEnabled && console.info('Trying to call ivWindow.. ring ring..');

            // "Hellooo, anyone there....?"
            ivWindow.postMessage('init', targetOrigin);
            setTimeout(initWindowCommunication, 1000);
        }
    }

    /*
     * Keep alive function that pings ImageVault window every second
     */
    function pingIv() {
        if (ivWindowCommunicating) {
            if (typeof ivWindow.opener !== 'object') {
                // window was closed
                closeWindow();
                return;
            }
            ivWindow.postMessage('ping', targetOrigin);
            logEnabled && console.info('Ping! ->');
        }
    }

    /*
     * Handler for incoming postMessages
     */
    function messageEvent(message) {
        // Ignore messages not for us.
        if (message.origin !== targetOrigin) {
            logEnabled && console.info('Message received to another origin: (' + message.origin + ' != ' + targetOrigin + '): ' + message.data);
            return;
        }

        switch (message.data) {
            case 'initReceived':
                logEnabled && console.info('Init received!');
                ivWindowCommunicating = true;
                pingTimer = setInterval(pingIv, 1000);
                break;

            case 'close':
                closeWindow();
                break;

            case 'pong':
                logEnabled && console.info('Pong! <-');
                break;

            default:
                // all other messages are insert messages
                logEnabled && console.info('Message: ' + message.data);
                {
                    const msgData = JSON.parse(message.data);
                    eventDispatcher.fire('ivWinClosed', { media: msgData });
                }
        }
    }

    /*
     * Inserts media (if any) into the editor
     */
    function addMediaToEditor(media) {
        if (media) {
            editor.insertContent(media.MediaConversions[0].Html);

            // todo: Add this if we want to handle video in editor instead of images if not Original
            //    if(media.ContentType.indexOf("video") !== -1)
            //        editor.insertContent(media.MediaConversions[2].Html);
            //    else
            //        editor.insertContent(media.MediaConversions[0].Html);
        }
    }

    /*
     * Closes and cleans up the window and handlers
     */
    function closeWindow() {
        try {
            ivWindow.opener.removeEventListener('message', messageEvent);
            ivWindow.close();
        } catch (e) {

        } finally {
            ivWindowCommunicating = false;
            eventDispatcher.fire('ivWinClosed', { media: null });
        }
    }

    /*
     * TinyMCE metadata shows up in the ? menu
     */
    return {
        getMetadata: function () {
            return {
                name: 'ImageVault',
                url: 'https://www.imagevault.se'
            };
        }
    };
});