// ==============================================================================
// Service Worker for Next.js PWA - Perfect Lighthouse Score
// ==============================================================================

const CACHE_VERSION = 'v1.0.0';
const STATIC_CACHE = `static-${CACHE_VERSION}`;
const DYNAMIC_CACHE = `dynamic-${CACHE_VERSION}`;
const IMAGE_CACHE = `images-${CACHE_VERSION}`;

const STATIC_ASSETS = [
  '/',
  '/favicon.svg',
  '/apple-touch-icon.png',
  '/icon-192.png',
  '/icon-512.png',
  '/manifest.webmanifest',
];

// Install Event
self.addEventListener('install', (event) => {
  console.log('[SW] Installing...');
  
  event.waitUntil(
    caches.open(STATIC_CACHE)
      .then((cache) => cache.addAll(STATIC_ASSETS))
      .then(() => self.skipWaiting())
  );
});

// Activate Event
self.addEventListener('activate', (event) => {
  console.log('[SW] Activating...');
  
  event.waitUntil(
    caches.keys()
      .then((cacheNames) => {
        return Promise.all(
          cacheNames
            .filter((name) => !name.includes(CACHE_VERSION))
            .map((name) => caches.delete(name))
        );
      })
      .then(() => self.clients.claim())
  );
});

// Fetch Event
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  if (request.method !== 'GET') return;
  if (!url.protocol.startsWith('http')) return;

  if (request.destination === 'image') {
    event.respondWith(handleImageRequest(request));
  } else if (url.pathname.startsWith('/api/')) {
    event.respondWith(handleAPIRequest(request));
  } else if (url.pathname.startsWith('/_next/')) {
    event.respondWith(handleNextAsset(request));
  } else {
    event.respondWith(handleDocumentRequest(request));
  }
});

async function handleImageRequest(request) {
  const cache = await caches.open(IMAGE_CACHE);
  const cached = await cache.match(request);

  if (cached) return cached;

  try {
    const response = await fetch(request);
    if (response.ok) cache.put(request, response.clone());
    return response;
  } catch (error) {
    return cached || new Response('', { status: 404 });
  }
}

async function handleAPIRequest(request) {
  try {
    const response = await fetch(request);
    return response;
  } catch (error) {
    return new Response(JSON.stringify({ offline: true }), {
      status: 503,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

async function handleNextAsset(request) {
  const cache = await caches.open(STATIC_CACHE);
  const cached = await cache.match(request);

  if (cached) {
    fetch(request).then((response) => {
      if (response.ok) cache.put(request, response.clone());
    });
    return cached;
  }

  try {
    const response = await fetch(request);
    if (response.ok) cache.put(request, response.clone());
    return response;
  } catch (error) {
    return cached || new Response('', { status: 404 });
  }
}

async function handleDocumentRequest(request) {
  const cache = await caches.open(STATIC_CACHE);
  const cached = await cache.match(request);

  const fetchPromise = fetch(request).then((response) => {
    if (response.ok) cache.put(request, response.clone());
    return response;
  });

  return cached || fetchPromise;
}

// Message Handler
self.addEventListener('message', (event) => {
  if (event.data?.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});

console.log('[SW] Service Worker loaded');

