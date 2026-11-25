# Correcteur IA — version iOS (clavier)

iOS interdit la bulle flottante et la lecture des autres applis : l'équivalent est un **clavier personnalisé**.
Le clavier lit le texte du champ, l'envoie à Groq, puis le remplace.

## Obtenir l'IPA sans Mac (GitHub Actions)
1. Crée un dépôt GitHub (privé ou public) et envoie-y TOUT ce dossier (la racine du dépôt = ce dossier).
2. Onglet *Actions* > *Build IPA* > *Run workflow*.
3. Quand c'est vert, télécharge l'artefact `Correcteur-ipa` (contient `Correcteur.ipa`, non signé).

## Installer l'IPA depuis Windows
- Installe iTunes + iCloud (versions du site d'Apple), puis Sideloadly (sideloadly.io).
- Branche l'iPhone, glisse `Correcteur.ipa` dans Sideloadly, entre ton identifiant Apple, *Start*.
- iPhone : Réglages > Général > VPN et gestion de l'appareil > fais confiance à ton compte ; active le Mode développeur (Réglages > Confidentialité et sécurité).
- Compte Apple gratuit : l'appli expire au bout de 7 jours (il faut la réinstaller).

## Avec un Mac
brew install xcodegen && xcodegen generate && open Correcteur.xcodeproj
Choisis ton équipe (Signing) pour les 2 cibles, puis Run sur l'iPhone.

## Activer le clavier
Réglages > Général > Clavier > Claviers > Ajouter > Correcteur IA > touche-le > Autoriser l'accès complet.
Si la clé Groq n'est pas partagée avec le clavier : copie-la, ouvre le clavier et touche 🔑.
