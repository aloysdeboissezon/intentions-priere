# Intentions de prière

Application web (sans compte, en français) pour confier une intention de prière ou prier pour celles des autres, au service des pèlerins de l'Ordre de Malte France.

- `index.html` : toute l'application (une seule page, installable sur téléphone).
- `manifest.webmanifest`, `sw.js`, `icon-*.png` : installation sur l'écran d'accueil et mode hors ligne minimal.

## Fonctionnement
- Base de données : Supabase, projet « intentions-priere ». Tables `intentions`, `journal`, `benevole_code`, protégées par des règles RLS.
  - Le public lit les intentions non masquées et peut en déposer.
  - Prières et signalements passent par les fonctions `prier` et `signaler` (une fois par appareil et par intention).
  - L'espace bénévoles (liste Lourdes, PDF à imprimer, modération) exige un code vérifié côté base.
- Changer le code bénévole : fonction `admin_changer_code(ancien, nouveau)` (10 caractères minimum).
- La clé présente dans `index.html` est la clé publique « anon » : elle est faite pour être visible.
- Un projet Supabase gratuit se met en pause après 7 jours sans activité : prévoir un réveil automatique avant le pèlerinage.

## Version
v42 (novembre 2026) : textes d'accueil et de la case Grotte ; 500 intentions affichées au plus (les plus anciennes disparaissent) ; les moins priées passent en premier ; fichier Word pour la Grotte avec rappel à 200 ; rappel quotidien par notification (voir supabase/).

## Rappels quotidiens et fichier Word (Supabase)
- Migration : colonne `intentions.envoye_le`, fonction `admin_marquer_envoyees`, tables `config_push` et `abonnements_rappel`, fonctions `abonner_rappel` / `desabonner_rappel`.
- `supabase/rappels/index.ts` : fonction Edge qui envoie le rappel (push web sans texte, signé VAPID). `supabase/rappels.sql` : planification quotidienne (pg_cron).
- La clé privée VAPID et le jeton restent dans la table `config_push` (illisible par le public) : ne jamais les écrire dans le dépôt.
