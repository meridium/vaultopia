"use strict";

/*
 * Simple proxy script that redirects incoming messages
 * to ImageVault through an iframe. Message replies are
 * redirected back to caller.
 */

/*
 * Helper method to get specific query parameter from querystring
 */
function getQueryStringParameterByName(name) {
    var url = window.location.href;
    name = name.replace(/[\[\]]/g, '\\$&');
    var regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)');
    var results = regex.exec(url);

    if (!results) {
        return null;
    }

    if (!results[2]) {
        return '';
    }

    return decodeURIComponent(results[2].replace(/\+/g, ' '));
}

//is true when returning from iv
var loggedIn = !!getQueryStringParameterByName("loggedIn");
//is true if we should try to route via iv
var forceLogin = !!getQueryStringParameterByName("forceLogin");
var imageVaultBaseUrl = getQueryStringParameterByName('imageVaultBaseUrl');

if (forceLogin && !loggedIn) {
    //mark redirect with logged in to shortcut forceLogin
    var redirectUrl = window.location.href+'&loggedIn=1';
    //redirect to iv (requires iv 5.12)
    window.location = imageVaultBaseUrl + "?redirectAfterLogin=" + encodeURIComponent(redirectUrl);
} else {


    document.addEventListener('DOMContentLoaded',
        function(event) {
            // Input commands to ImageVault:
            //
            // init:    initialize communication
            // ping:    keep connection alive
            const incomingCommands = ['init', 'ping'];

            const iframe = document.getElementById('mainframe');

            // get ImageVault origin/URL from query string
            var ivOrigin = imageVaultBaseUrl;

            // if no imageVaultBaseUrl, use default '/ImageVault/'
            if (!ivOrigin || ivOrigin.length === 0) {
                ivOrigin = '/ImageVault/';
            }

            // set iframe to ImageVault origin with query string
            iframe.src = ivOrigin + window.location.search;

            // Make sure target origin does not have trailing slash
            if (ivOrigin.slice(-1) === '/') {
                ivOrigin = ivOrigin.slice(0, -1);
            }

            // polyfill for location.origin
            if (typeof location.origin === 'undefined') {
                location.origin = location.protocol + '//' + location.host;
            }

            // If ImageVault origin is relative URL, i.e. subsite ('/ImageVault/')
            // Message received and sender will be the same.
            if (ivOrigin.indexOf('/') === 0) {
                ivOrigin = location.origin;
            }

            // init messaging
            window.addEventListener('message', messageEvent);

            /*
             * Handle message events.
             *
             * Forwards from opener to ImageVault or returns from ImageVault to opener.
             */
            function messageEvent(message) {
                if (verifyInputMessage(message)) {
                    // forward message -> to ImageVault
                    iframe.contentWindow.postMessage(message.data, ivOrigin);
                } else if (verifyOutputMessage(message)) {
                    // reply to opener <- from ImageVault
                    window.opener.postMessage(message.data, location.origin);
                }
            }

            /*
             * Verifies a message as input to ImageVault:
             * Check that message origin is from us and make sure the message data is a valid input command.
             */
            function verifyInputMessage(message) {
                return incomingCommands.indexOf(message.data) !== -1 && message.origin === location.origin;
            }

            /*
             * Verifies a message as output from ImageVault:
             * Check that message origin is from ImageVault.
             */
            function verifyOutputMessage(message) {
                return message.origin === ivOrigin;
            }


        });
}