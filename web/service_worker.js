// Service Worker for Near Field Kore PWA
const CACHE_NAME = 'chikaba-kore-v1';
const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/favicon.png',
  'https://fonts.googleapis.com/css2?family=Noto+Sans+JP:wght@400;500;700&display=swap'
];

// Install Event - Cache essential assets
self.addEventListener('install', (event) => {
  console.log('Service Worker installing...');
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      console.log('Caching essential assets');
      return cache.addAll(STATIC_ASSETS).catch((err) => {
        console.warn('Failed to cache some assets:', err);
        // Continue even if some assets fail to cache
      });
    })
  );
  self.skipWaiting();
});

// Activate Event - Clean up old caches
self.addEventListener('activate', (event) => {
  console.log('Service Worker activating...');
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME) {
            console.log('Deleting old cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
  self.clients.claim();
});

// Fetch Event - Network first, fallback to cache
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // Skip cross-origin requests
  if (url.origin !== location.origin) {
    return;
  }

  // Network first strategy for API calls
  if (url.pathname.startsWith('/api/')) {
    event.respondWith(networkFirst(request));
  }
  // Cache first strategy for assets
  else if (request.method === 'GET') {
    event.respondWith(cacheFirst(request));
  }
  // Network only for other requests (POST, PUT, DELETE)
  else {
    event.respondWith(networkOnly(request));
  }
});

// Cache first strategy
async function cacheFirst(request) {
  const cache = await caches.open(CACHE_NAME);
  const cached = await cache.match(request);

  if (cached) {
    return cached;
  }

  try {
    const response = await fetch(request);

    // Cache successful responses
    if (response.ok) {
      cache.put(request, response.clone());
    }

    return response;
  } catch (error) {
    console.log('Fetch failed; returning offline page', error);
    // Return a fallback response
    return new Response('Offline - Content not available', {
      status: 503,
      statusText: 'Service Unavailable',
      headers: new Headers({
        'Content-Type': 'text/plain'
      })
    });
  }
}

// Network first strategy
async function networkFirst(request) {
  try {
    const response = await fetch(request);

    // Cache successful responses
    if (response.ok) {
      const cache = await caches.open(CACHE_NAME);
      cache.put(request, response.clone());
    }

    return response;
  } catch (error) {
    console.log('Network request failed, checking cache', error);
    const cache = await caches.open(CACHE_NAME);
    const cached = await cache.match(request);

    if (cached) {
      return cached;
    }

    // Return offline response
    return new Response(
      JSON.stringify({
        error: 'Offline',
        message: 'You are currently offline. Please check your connection.'
      }),
      {
        status: 503,
        statusText: 'Service Unavailable',
        headers: new Headers({
          'Content-Type': 'application/json'
        })
      }
    );
  }
}

// Network only strategy
async function networkOnly(request) {
  try {
    return await fetch(request);
  } catch (error) {
    console.log('Network request failed', error);
    return new Response(
      JSON.stringify({
        error: 'Network Error',
        message: 'Unable to complete this action offline.'
      }),
      {
        status: 503,
        statusText: 'Service Unavailable',
        headers: new Headers({
          'Content-Type': 'application/json'
        })
      }
    );
  }
}

// Background Sync for offline actions
self.addEventListener('sync', (event) => {
  console.log('Background sync event:', event.tag);

  if (event.tag === 'sync-reviews') {
    event.waitUntil(syncPendingReviews());
  } else if (event.tag === 'sync-favorites') {
    event.waitUntil(syncPendingFavorites());
  }
});

async function syncPendingReviews() {
  try {
    // Get pending reviews from IndexedDB
    const db = await openDatabase();
    const pendingReviews = await getPendingReviews(db);

    for (const review of pendingReviews) {
      await submitReview(review);
    }

    console.log('Reviews synced successfully');
  } catch (error) {
    console.error('Failed to sync reviews:', error);
    throw error;
  }
}

async function syncPendingFavorites() {
  try {
    const db = await openDatabase();
    const pendingFavorites = await getPendingFavorites(db);

    for (const favorite of pendingFavorites) {
      await submitFavorite(favorite);
    }

    console.log('Favorites synced successfully');
  } catch (error) {
    console.error('Failed to sync favorites:', error);
    throw error;
  }
}

// IndexedDB helpers
async function openDatabase() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open('chikaba_kore', 1);

    request.onerror = () => reject(request.error);
    request.onsuccess = () => resolve(request.result);

    request.onupgradeneeded = (event) => {
      const db = event.target.result;
      if (!db.objectStoreNames.contains('pending_reviews')) {
        db.createObjectStore('pending_reviews', { keyPath: 'id' });
      }
      if (!db.objectStoreNames.contains('pending_favorites')) {
        db.createObjectStore('pending_favorites', { keyPath: 'id' });
      }
    };
  });
}

async function getPendingReviews(db) {
  return new Promise((resolve, reject) => {
    const transaction = db.transaction(['pending_reviews'], 'readonly');
    const store = transaction.objectStore('pending_reviews');
    const request = store.getAll();

    request.onerror = () => reject(request.error);
    request.onsuccess = () => resolve(request.result);
  });
}

async function getPendingFavorites(db) {
  return new Promise((resolve, reject) => {
    const transaction = db.transaction(['pending_favorites'], 'readonly');
    const store = transaction.objectStore('pending_favorites');
    const request = store.getAll();

    request.onerror = () => reject(request.error);
    request.onsuccess = () => resolve(request.result);
  });
}

// Push Notification Event
self.addEventListener('push', (event) => {
  console.log('Push notification received:', event.data);

  if (!event.data) {
    return;
  }

  let notificationData = {
    title: '近場コレ',
    body: 'New notification',
    badge: '/icons/Icon-192.png',
    icon: '/icons/Icon-192.png'
  };

  try {
    notificationData = event.data.json();
  } catch (e) {
    notificationData.body = event.data.text();
  }

  event.waitUntil(
    self.registration.showNotification(notificationData.title, notificationData)
  );
});

// Notification Click Event
self.addEventListener('notificationclick', (event) => {
  console.log('Notification clicked:', event.notification);

  event.notification.close();

  event.waitUntil(
    clients.matchAll({ type: 'window' }).then((clientList) => {
      // Check if app is already open
      for (const client of clientList) {
        if (client.url === '/' && 'focus' in client) {
          return client.focus();
        }
      }

      // Open app if not already open
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});

console.log('Service Worker loaded');
