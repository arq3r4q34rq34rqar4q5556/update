/**
 * A generic service worker that intercepts a request for a specific 'original' URL
 * and responds with a 'modified' URL. The URLs are passed as query parameters
 * when the service worker is registered.
 * e.g., /sw.js?original=...&modified=...
 */

self.addEventListener('install', () => {
  // This forces the waiting service worker to become the active service worker.
  self.skipWaiting();
});

self.addEventListener('activate', event => {
  // This allows an active service worker to take control of the page without a reload.
  event.waitUntil(clients.claim());
});

self.addEventListener('fetch', event => {
  // Get the configuration from the service worker's own URL.
  const params = new URL(self.location).searchParams;
  const originalUrl = params.get('original');
  const modifiedUrl = params.get('modified');

  // If the configuration isn't set, or if the request doesn't match, do nothing.
  if (!originalUrl || !modifiedUrl || !event.request.url.includes(originalUrl)) {
    return;
  }

  // Log the interception and replacement.
  console.log(`[Service Worker] Intercepting: ${event.request.url}`);
  console.log(`[Service Worker] Responding with: ${modifiedUrl}`);

  // Create a new, clean request to the modified URL to avoid any issues
  // with the original request's headers or mode.
  const newRequest = new Request(modifiedUrl, {
    mode: 'cors',       // Important for cross-origin requests
    credentials: 'omit' // You might need 'include' depending on the target server
  });

  // Intercept the request and respond with our new request.
  event.respondWith(fetch(newRequest));
});
