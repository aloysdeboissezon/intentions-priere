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
