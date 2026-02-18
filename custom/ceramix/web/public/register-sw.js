// Service Worker Registration Script
// This script registers the service worker for PWA functionality

if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    const swUrl = '/sw.js';
    
    navigator.serviceWorker
      .register(swUrl)
      .then((registration) => {
        // Only log in development (check if on localhost)
        const isDev = window.location.hostname === 'localhost' || window.location.hostname.includes('localhost');
        if (isDev) {
          console.log('[SW] Service Worker registered:', registration.scope);
        }
        
        // Check for updates
        registration.addEventListener('updatefound', () => {
          const newWorker = registration.installing;
          if (newWorker) {
            newWorker.addEventListener('statechange', () => {
              if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
                // Only show notification in production
                const isDev = window.location.hostname === 'localhost' || window.location.hostname.includes('localhost');
                if (!isDev && confirm('Nowa wersja aplikacji dostępna. Odświeżyć stronę?')) {
                  newWorker.postMessage({ type: 'SKIP_WAITING' });
                  window.location.reload();
                }
              }
            });
          }
        });
      })
      .catch((error) => {
        // Always log errors
        console.error('[SW] Service Worker registration failed:', error);
      });
    
    // Handle service worker updates (silently in background)
    let refreshing = false;
    navigator.serviceWorker.addEventListener('controllerchange', () => {
      if (!refreshing && navigator.serviceWorker.controller) {
        refreshing = true;
        // Silent reload - don't spam console
        window.location.reload();
      }
    });
  });
} else {
  console.warn('[SW] Service Workers not supported in this browser');
}

