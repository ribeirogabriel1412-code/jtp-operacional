// JTP Operacional — Service Worker v2.2
// Força limpeza de cache a cada novo deploy

const CACHE_NAME = 'jtp-v2-2';
const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/app-mobile.html',
  '/manifest.json'
];

// Instala e limpa caches antigos
self.addEventListener('install', event => {
  // Força ativação imediata sem esperar
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => {
      return cache.addAll(STATIC_ASSETS).catch(() => {});
    })
  );
});

// Ativa e remove caches antigos
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(
        keys
          .filter(key => key !== CACHE_NAME)
          .map(key => {
            console.log('[SW] Removendo cache antigo:', key);
            return caches.delete(key);
          })
      )
    ).then(() => self.clients.claim())
  );
});

// Estratégia: Network First para HTML, Cache First para assets estáticos
self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);

  // Sempre buscar HTML do servidor (nunca do cache)
  if (url.pathname.endsWith('.html') || url.pathname === '/') {
    event.respondWith(
      fetch(event.request)
        .then(response => {
          // Atualiza o cache com a versão mais recente
          const responseClone = response.clone();
          caches.open(CACHE_NAME).then(cache => cache.put(event.request, responseClone));
          return response;
        })
        .catch(() => caches.match(event.request))
    );
    return;
  }

  // Para outros recursos: cache first
  event.respondWith(
    caches.match(event.request).then(cached => {
      return cached || fetch(event.request);
    })
  );
});
