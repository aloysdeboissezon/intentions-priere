// Mode hors ligne minimal : la page et les icônes sont gardées en mémoire ; les intentions viennent toujours du réseau.
const CACHE = "intentions-v11";
const FICHIERS = ["./", "index.html", "manifest.webmanifest", "icon-192.png", "icon-512.png"];
self.addEventListener("install", (e) => { e.waitUntil(caches.open(CACHE).then((c) => c.addAll(FICHIERS)).then(() => self.skipWaiting())); });
self.addEventListener("activate", (e) => { e.waitUntil(caches.keys().then((ks) => Promise.all(ks.filter((k) => k !== CACHE).map((k) => caches.delete(k)))).then(() => self.clients.claim())); });
self.addEventListener("fetch", (e) => {
  const r = e.request; const u = new URL(r.url);
  if (r.method !== "GET" || u.origin !== location.origin) return;
  e.respondWith(fetch(r).then((rep) => { const copie = rep.clone(); caches.open(CACHE).then((c) => c.put(r, copie)); return rep; }).catch(() => caches.match(r).then((m) => m || caches.match("index.html"))));
});
