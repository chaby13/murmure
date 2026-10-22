# Murmure

*Lisez, écoutez, traduisez. En toute liberté.* Une application Chabane DEV.

Lecture PDF à voix douce, transcription et traduction anglais ⇄ français, traitées sur le téléphone.

**État : lots L0 et L2 (en partie).** Navigation, thème, logo, et une vraie bibliothèque locale (SQLite + import PDF en stockage privé). Aucun moteur local (PDF, OCR, voix, transcription, traduction) n'est encore intégré : l'application le dit à chaque endroit concerné. Voir `docs/CADRAGE_V1.md` pour le PRD, l'architecture, les risques et le plan.

## Lancer

```
flutter pub get
flutter analyze
flutter test
flutter run
```

Coordonnées de l'éditeur (facultatives, affichées dans À propos) :

```
flutter run --dart-define=MURMURE_DEV_WEBSITE=https://... --dart-define=MURMURE_DEV_CONTACT=...
```
