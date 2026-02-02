// ==UserScript==
// @name         Sigma-Client Loader
// @namespace    http://tampermonkey.net/
// @version      1.0
// @description  Loads the Sigma-Client user interface into blob.io.
// @author       Sigma
// @match        https://blob.io/*
// @grant        GM_xmlhttpRequest
// @connect      YOUR_SERVER_URL_HERE
// @run-at       document-start
// ==/UserScript==

(function() {
    'use strict';

    // IMPORTANT: Replace this with the actual URL of your running server
    const serverUrl = 'https://YOUR_SERVER_URL_HERE';
    const loaderUrl = `${serverUrl}/skinshop`;

    console.log('Sigma-Client: Initializing...');

    // Use GM_xmlhttpRequest to bypass CORS restrictions
    GM_xmlhttpRequest({
        method: 'GET',
        url: loaderUrl,
        onload: function(response) {
            if (response.status >= 200 && response.status < 400) {
                console.log('Sigma-Client: Loader content fetched successfully.');
                
                // When the DOM is ready, inject the client
                document.addEventListener('DOMContentLoaded', () => {
                    // Create a new div element to hold the client's HTML
                    const sigmaDiv = document.createElement('div');
                    sigmaDiv.innerHTML = response.responseText;
                    
                    // Append the new UI to the body of the page
                    document.body.appendChild(sigmaDiv);

                    console.log('Sigma-Client: UI injected. The client should now be active.');
                });

            } else {
                console.error(`Sigma-Client: Failed to fetch loader content. Status: ${response.status}`);
                alert('Sigma-Client: Could not load client resources. The server might be down or the URL in the script is incorrect.');
            }
        },
        onerror: function(response) {
            console.error('Sigma-Client: An error occurred during the request.', response);
            alert('Sigma-Client: An error occurred while trying to load the client. Check the console and make sure the server is running.');
        }
    });
})();
