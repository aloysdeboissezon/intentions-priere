// Envoi du rappel quotidien de prière (notification push web, sans texte : le texte est écrit par sw.js).
// Appelée chaque matin par pg_cron (voir rappels.sql) avec un jeton secret. Aucun service payant, aucune carte bancaire.
import { createClient } from "npm:@supabase/supabase-js@2";

const SUJET = "https://aloysdeboissezon.github.io/intentions-priere/"; // identifiant de l'expéditeur (VAPID), sans donnée personnelle
const b64u = (u: Uint8Array) => btoa(String.fromCharCode(...u)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
const enc = (o: unknown) => b64u(new TextEncoder().encode(JSON.stringify(o)));

async function jeton(endpoint: string, cle: JsonWebKey) {
  const k = await crypto.subtle.importKey("jwk", cle, { name: "ECDSA", namedCurve: "P-256" }, false, ["sign"]);
  const corps = enc({ typ: "JWT", alg: "ES256" }) + "." + enc({ aud: new URL(endpoint).origin, exp: Math.floor(Date.now() / 1000) + 12 * 3600, sub: SUJET });
  const sig = new Uint8Array(await crypto.subtle.sign({ name: "ECDSA", hash: "SHA-256" }, k, new TextEncoder().encode(corps)));
  return corps + "." + b64u(sig);
}

Deno.serve(async (req) => {
  const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: cfg } = await db.from("config_push").select("*").single();
  if (!cfg || req.headers.get("x-jeton") !== cfg.jeton) return new Response("non autorisé", { status: 401 });
  const { data: abos } = await db.from("abonnements_rappel").select("endpoint");
  let envoyes = 0, retires = 0, erreurs = 0;
  for (const a of abos || []) {
    try {
      const r = await fetch(a.endpoint, { method: "POST", headers: { TTL: "43200", Urgency: "low", Authorization: "vapid t=" + await jeton(a.endpoint, cfg.cle_privee) + ", k=" + cfg.cle_publique } });
      if (r.status === 404 || r.status === 410) { await db.from("abonnements_rappel").delete().eq("endpoint", a.endpoint); retires++; }
      else if (r.ok) envoyes++; else erreurs++;
    } catch (_) { erreurs++; }
  }
  return Response.json({ envoyes, retires, erreurs });
});
