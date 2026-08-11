// Service worker: offline app shell + web push.
//
// Bump SW_VERSION whenever the caching rules below change — the byte diff is
// what makes browsers pick up the new worker, and activate() then drops every
// cache that does not match the current name.
const SW_VERSION = 'v1';
const CACHE = `meowny-${SW_VERSION}`;

// Enough to boot the app offline; everything else is cached as it is fetched.
const SHELL = [
  '/',
  '/index.html',
  '/flutter_bootstrap.js',
  '/manifest.json',
  '/favicon.png',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
];

// Rarely change and harmless when a version behind — served straight from cache.
const CACHE_FIRST = /^\/(icons\/|favicon\.png$)/;

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches
      .open(CACHE)
      // Individual misses (a renamed asset, a 404) must not fail the install.
      .then((cache) => Promise.allSettled(SHELL.map((url) => cache.add(url))))
      .then(() => self.skipWaiting()),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) =>
        Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))),
      )
      .then(() => self.clients.claim()),
  );
});

async function cacheFirst(request) {
  const cached = await caches.match(request);
  if (cached) return cached;
  const response = await fetch(request);
  await put(request, response);
  return response;
}

// Network-first keeps main.dart.js and the shell consistent with each other:
// online users always get the freshly deployed set, and the cache is only a
// fallback for when the network is gone.
async function networkFirst(request, fallbackUrl) {
  try {
    const response = await fetch(request);
    await put(request, response);
    return response;
  } catch (e) {
    const cached =
      (await caches.match(request)) ||
      (fallbackUrl ? await caches.match(fallbackUrl) : undefined);
    if (cached) return cached;
    throw e;
  }
}

async function put(request, response) {
  // Opaque, partial and error responses are not safe to replay from cache.
  if (!response || !response.ok || response.type !== 'basic') return;
  const cache = await caches.open(CACHE);
  await cache.put(request, response.clone());
}

self.addEventListener('fetch', (event) => {
  const { request } = event;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  // Supabase and any other cross-origin traffic goes straight to the network.
  if (url.origin !== self.location.origin) return;

  if (request.mode === 'navigate') {
    event.respondWith(networkFirst(request, '/index.html'));
    return;
  }

  if (CACHE_FIRST.test(url.pathname)) {
    event.respondWith(cacheFirst(request));
    return;
  }

  event.respondWith(networkFirst(request));
});

// ── Web push ─────────────────────────────────────────────────────────────────

self.addEventListener('push', (event) => {
  const data = event.data?.json() ?? {};
  event.waitUntil(
    self.registration.showNotification(data.title ?? 'Meowny 🐱', {
      body: data.body ?? '',
      icon: data.icon ?? '/icons/Icon-192.png',
      badge: data.badge ?? '/icons/Icon-192.png',
      tag: 'meowny-transaction',
      renotify: true,
      data: { url: '/' },
    }),
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    clients
      .matchAll({ type: 'window', includeUncontrolled: true })
      .then((clientList) => {
        for (const client of clientList) {
          if ('focus' in client) return client.focus();
        }
        if (clients.openWindow) return clients.openWindow('/');
      }),
  );
});
