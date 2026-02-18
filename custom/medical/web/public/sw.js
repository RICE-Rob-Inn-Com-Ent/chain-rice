// Ceramix Service Worker
// Provides offline support and caching for PWA functionality

const CACHE_NAME = 'ceramix-v1';
const RUNTIME_CACHE = 'ceramix-runtime-v1';
const STATIC_CACHE = 'ceramix-static-v1';

// Assets to cache immediately on install
const PRECACHE_ASSETS = [
  '/',
  '/favicon.svg',
  '/manifest.json',
  '/sign-in',
  '/sign-up',
];

// Install event - cache static assets
self.addEventListener('install', (event) => {
  console.log('[SW] Service Worker installing...');
  
  event.waitUntil(
    caches.open(STATIC_CACHE)
      .then((cache) => {
        console.log('[SW] Caching static assets');
        return cache.addAll(PRECACHE_ASSETS.map(url => new Request(url, { cache: 'reload' })));
      })
      .then(() => {
        console.log('[SW] Static assets cached');
        return self.skipWaiting(); // Activate immediately
      })
      .catch((error) => {
        console.error('[SW] Error caching static assets:', error);
      })
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  console.log('[SW] Service Worker activating...');
  
  event.waitUntil(
    caches.keys()
      .then((cacheNames) => {
        return Promise.all(
          cacheNames
            .filter((cacheName) => {
              // Delete old caches
              return cacheName !== CACHE_NAME &&
                     cacheName !== RUNTIME_CACHE &&
                     cacheName !== STATIC_CACHE;
            })
            .map((cacheName) => {
              console.log('[SW] Deleting old cache:', cacheName);
              return caches.delete(cacheName);
            })
        );
      })
      .then(() => {
        console.log('[SW] Service Worker activated');
        return self.clients.claim(); // Take control immediately
      })
  );
});

// Fetch event - serve from cache, fallback to network
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // Skip cross-origin requests
  if (url.origin !== location.origin) {
    return;
  }

  // Skip API requests (always fetch fresh)
  if (url.pathname.startsWith('/api/')) {
    return;
  }

  // Strategy: Cache First for static assets, Network First for pages
  event.respondWith(
    caches.match(request)
      .then((cachedResponse) => {
        // If cached and it's a static asset, return it
        if (cachedResponse && (request.url.includes('.css') || 
                                request.url.includes('.js') || 
                                request.url.includes('.svg') || 
                                request.url.includes('.png') || 
                                request.url.includes('.jpg') ||
                                request.url.includes('.woff'))) {
          return cachedResponse;
        }

        // For pages, try network first
        return fetch(request)
          .then((response) => {
            // Don't cache non-successful responses
            if (!response || response.status !== 200 || response.type !== 'basic') {
              return response;
            }

            // Clone the response
            const responseToCache = response.clone();

            // Cache the response
            caches.open(RUNTIME_CACHE)
              .then((cache) => {
                cache.put(request, responseToCache);
              });

            return response;
          })
          .catch(() => {
            // Network failed, try cache
            if (cachedResponse) {
              return cachedResponse;
            }

            // Return offline page if available
            return caches.match('/sign-in');
          });
      })
  );
});

// Message handler for cache updates
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
  
  if (event.data && event.data.type === 'CACHE_URLS') {
    event.waitUntil(
      caches.open(RUNTIME_CACHE)
        .then((cache) => {
          return cache.addAll(event.data.urls);
        })
    );
  }
});








