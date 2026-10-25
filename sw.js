// Mode hors ligne minimal : la page et les icônes sont gardées en mémoire ; les intentions viennent toujours du réseau.
const CACHE = "intentions-v18";
const FICHIERS = ["./", "index.html", "manifest.webmanifest", "icon-192.png", "icon-512.png"];
self.addEventListener("install", (e) => { e.waitUntil(caches.open(CACHE).then((c) => c.addAll(FICHIERS)).then(() => self.skipWaiting())); });
self.addEventListener("activate", (e) => { e.waitUntil(caches.keys().then((ks) => Promise.all(ks.filter((k) => k !== CACHE).map((k) => caches.delete(k)))).then(() => self.clients.claim())); });
self.addEventListener("fetch", (e) => {
  const r = e.request; const u = new URL(r.url);
  if (r.method !== "GET" || u.origin !== location.origin) return;
  e.respondWith(fetch(r).then((rep) => { const copie = rep.clone(); caches.open(CACHE).then((c) => c.put(r, copie)); return rep; }).catch(() => caches.match(r).then((m) => m || caches.match("index.html"))));
});

self.addEventListener("periodicsync", (e) => {
  if (e.tag === "rappel") e.waitUntil(self.registration.showNotification("Intentions de prière", { body: "Des intentions attendent votre prière.", icon: "icon-192.png", badge: "icon-192.png", tag: "rappel", data: { url: "./#prier" } }));
});
self.addEventListener("notificationclick", (e) => {
  e.notification.close();
  e.waitUntil(self.clients.matchAll({ type: "window" }).then((cs) => { const c = cs.find((x) => "focus" in x); return c ? c.focus() : self.clients.openWindow((e.notification.data && e.notification.data.url) || "./"); }));
});
