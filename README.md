# Murmure

*Lisez, écoutez. En toute liberté.* Une application Chabane DEV.

Lecture PDF à voix douce et transcription, traitées sur le téléphone. L'onglet Découvrir propose des liens vers des radios, des livres et des livres audio gratuits, ouverts dans le navigateur.

**État : lots L0, L2 et L3 (en partie).** Navigation, thème, logo, vraie bibliothèque locale (SQLite + import PDF en stockage privé) et lecteur PDF local (PDFium) avec reprise de page et extraction du texte. Les moteurs OCR, voix, transcription et traduction ne sont pas encore intégrés : l'application le dit à chaque endroit concerné. Voir `docs/CADRAGE_V1.md` pour le PRD, l'architecture, les risques et le plan.

## Lancer

```
flutter pub get
flutter analyze
tool/fetch_pdfium.sh                                      # une fois, pour les tests du moteur PDF
tool/fetch_whisper_model.sh                               # une fois, modèle de transcription embarqué (≈ 57 Mo)
PDFIUM_PATH=.pdfium/lib/libpdfium.so flutter test
flutter run
```

Démonstration dans un navigateur (documents d'exemple) : `flutter run -d chrome -t lib/main_demo.dart`.

Coordonnées de l'éditeur (facultatives, affichées dans À propos) :

```
flutter run --dart-define=MURMURE_DEV_WEBSITE=https://... --dart-define=MURMURE_DEV_CONTACT=...
```
