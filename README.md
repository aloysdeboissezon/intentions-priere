# Site d'intentions de prière

- `index.html` : tout le site (une seule page). Il parle à la base Supabase du projet « intentions-priere ».
- Base : tables `intentions`, `journal`, `benevole_code` ; accès public limité par des règles RLS.
  - Le public lit seulement les intentions non masquées et peut en déposer.
  - Les prières et signalements passent par les fonctions `prier` et `signaler` (une fois par appareil).
  - L'espace bénévoles (liste Lourdes, PDF, modération) exige le code bénévole, vérifié côté base.
- Changer le code bénévole : appeler la fonction `admin_changer_code(ancien, nouveau)` (10 caractères minimum).
- La clé dans `index.html` est la clé publique « anon » : elle est faite pour être visible.
- Les projets gratuits Supabase se mettent en pause après 7 jours sans activité : prévoir un réveil automatique si besoin.
