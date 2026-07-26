// service-worker.js

const CACHE_NAME = "home-cache-v2";

// Files that are safe to cache.
// DO NOT cache "/" or any HTML pages during development.
const urlsToCache = [
  "/favicon.ico"
];

// Install the service worker
self.addEventListener("install", (event) => {
  console.log("Service Worker Installed");

  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(urlsToCache);
    })
  );

  self.skipWaiting();
});

// Activate the service worker
self.addEventListener("activate", (event) => {
  console.log("Service Worker Activated");

  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cache) => {
          if (cache !== CACHE_NAME) {
            return caches.delete(cache);
          }
        })
      );
    })
  );

  self.clients.claim();
});

// Fetch requests
self.addEventListener("fetch", (event) => {
  // Never cache HTML pages.
  // Always request them from Phoenix.
  if (event.request.mode === "navigate") {
    event.respondWith(fetch(event.request));
    return;
  }

  // Cache static assets only.
  event.respondWith(
    caches.match(event.request).then((cachedResponse) => {
      if (cachedResponse) {
        return cachedResponse;
      }

      return fetch(event.request).then((networkResponse) => {
        // Only cache successful GET requests.
        if (
          event.request.method === "GET" &&
          networkResponse.status === 200
        ) {
          const responseClone = networkResponse.clone();

          caches.open(CACHE_NAME).then((cache) => {
            cache.put(event.request, responseClone);
          });
        }

        return networkResponse;
      });
    })
  );
});