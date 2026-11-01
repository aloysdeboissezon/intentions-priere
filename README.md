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

## Crédits des images
- `main-croix.webp` (signe de croix animé) : photo « Raised arm of woman » par Vera Emilie, Pexels, https://www.pexels.com/photo/raised-arm-of-woman-20805371/ . Licence Pexels (https://www.pexels.com/license/) : utilisation gratuite, modification autorisée, attribution non obligatoire. Main détourée et réduite.
- `mains-jointes.webp` (animation « J'ai prié pour cette intention ») : photo « Close-up of hands praying with rosary beads » par ORBABZ, Pexels, https://www.pexels.com/photo/close-up-of-hands-praying-with-rosary-beads-34338555/ . Licence Pexels (https://www.pexels.com/license/) : utilisation gratuite, y compris commerciale, modification autorisée, attribution non obligatoire. Image détourée, recadrée et réduite pour l'application.
