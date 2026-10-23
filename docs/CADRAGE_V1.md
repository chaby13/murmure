# Murmure — Cadrage V1

*Lisez, écoutez, traduisez. En toute liberté.* · Éditeur : Chabane DEV · Version du document : 1.0 (22 octobre 2026)

Ce document couvre les étapes 1, 2 et 4 du prompt maître : le PRD priorisé, l'architecture Flutter avec sa grille de risques, et le plan d'implémentation en incréments testables. Le squelette Flutter qui l'accompagne est décrit à la fin, avec ce qui est réellement fait et ce qui ne l'est pas.

---

## 1. PRD — Cahier des charges V1

### 1.1 Vision et utilisateurs

Murmure est une application Android et iPhone pour se cultiver : lire un PDF à voix douce, transcrire une voix, et traduire entre l'anglais et le français, avec un traitement des données personnelles qui reste entièrement sur le téléphone.

Utilisateurs visés :

- **L'apprenant** qui lit des cours ou livres en anglais et veut écouter, traduire un passage et comparer les deux langues.
- **Le lecteur fatigué ou malvoyant** qui préfère écouter un document, écran verrouillé.
- **Le professionnel discret** qui enregistre une réunion ou une note et ne veut pas qu'elle quitte son téléphone.

### 1.2 Principes non négociables

1. Aucun envoi de PDF, audio, texte, transcription ou traduction vers un serveur. Pas de compte, pas d'analytique, pas de SDK publicitaire.
2. Le parcours principal fonctionne en mode avion dès la première ouverture (édition « autonome » avec modèles inclus).
3. Une fonction non implémentée n'est jamais présentée comme opérationnelle : elle est désactivée et étiquetée.
4. Aucune promesse « aucun réseau » ou « chiffrement total » avant audit objectif.
5. Licences des modèles, bibliothèques et polices vérifiées avant toute distribution.

### 1.3 Exigences fonctionnelles

Priorités : **P0** = lancement V1, **P1** = V1.1, **P2** = V2.

| ID | Exigence | Priorité | Ticket |
|---|---|---|---|
| F-01 | Importer un PDF depuis le stockage local | P0 | PDF-01 |
| F-02 | Recevoir un PDF depuis le menu Partager du système | P0 | PDF-01 |
| F-03 | Afficher les pages d'un PDF (défilement, zoom, aller à la page) | P0 | PDF-01 |
| F-04 | Extraire le texte d'un PDF numérique | P0 | PDF-02 |
| F-05 | Mémoriser et restaurer la position de lecture après fermeture | P0 | PDF-02 |
| F-06 | Lire le texte à voix haute en FR et EN avec voix locales | P0 | TTS-01 |
| F-07 | Contrôles lecture/pause, saut ±15 s ou phrase, vitesse, choix de voix | P0 | TTS-01 |
| F-08 | Lecture en arrière-plan et écran verrouillé, commandes système | P0 | TTS-02 |
| F-09 | Enregistrer au microphone (durée, pause, fin) | P0 | ASR-01 |
| F-10 | Importer un fichier audio (WAV, M4A, MP3 selon décodeurs retenus), erreur explicite sinon | P0 | ASR-02 |
| F-11 | Transcrire localement en FR ou EN | P0 | ASR-01 |
| F-12 | Corriger, copier et exporter une transcription en TXT | P0 | ASR-01 |
| F-13 | ~~Traduire localement un extrait EN → FR~~ (annulé le 23/10/2026 : modèles trop lourds) | — | TR-02 |
| F-14 | ~~Traduire localement un extrait FR → EN~~ (annulé le 23/10/2026 : modèles trop lourds) | — | TR-01 |
| F-15 | ~~Traduire une sélection de PDF ou une transcription~~ (annulé le 23/10/2026 : modèles trop lourds) | — | TR-01/02 |
| F-16 | ~~Écouter séparément l'original et la traduction~~ (annulé le 23/10/2026 : modèles trop lourds) | — | TTS-01 |
| F-17 | Bibliothèque locale : liste, recherche, filtres PDF/audio/transcriptions/favoris, tri, suppression | P0 | STORE-01 |
| F-18 | Paramètres : voix, vitesse, apparence clair/sombre, langue UI, espace des modèles | P0 | UI-01 |
| F-19 | Écran À propos : logo Chabane DEV, version issue du build, promesse locale exacte, licences, politique de confidentialité embarquée | P0 | BRAND-01, LEGAL-01 |
| F-20 | Exporter et supprimer toutes les données utilisateur | P0 | STORE-01 |
| F-21 | OCR local des PDF scannés | **P1** (P0 si vendu en V1) | OCR-01 |
| F-22 | Surlignage de la phrase prononcée | P1 | — |
| F-23 | Mode bilingue côte à côte | P1 | — |
| F-24 | Minuterie de sommeil | P1 | — |
| F-25 | Export SRT avec horodatages | P1 | — |
| F-26 | Mode lecture sépia, signets, annotations de base | P1 | — |
| F-27 | Historique local de traduction (optionnel, désactivable) | P1 | — |
| F-28 | Chiffrement optionnel des documents sensibles | P1 | — |
| F-29 | Identification de plusieurs intervenants | P2 | — |
| F-30 | Dictionnaires vocaux personnalisés | P2 | — |
| F-31 | Résumés et questions-réponses locaux sur un PDF | P2 | — |
| F-32 | Synchronisation entre appareils par export volontaire | P2 | — |

### 1.4 Exigences non fonctionnelles

| ID | Exigence | Priorité | Mesure de réception |
|---|---|---|---|
| NF-01 | Aucune requête sortante sur les parcours principaux | P0 | Capture réseau (proxy + mode avion) documentée sur Android et iPhone |
| NF-02 | Android : pas de permission `INTERNET` dans le build de production | P0 | Manifeste fusionné vérifié à chaque build release |
| NF-03 | Fonctionnement complet en mode avion dès la première ouverture | P0 | Test d'installation de l'édition autonome hors ligne |
| NF-04 | Stockage dans le répertoire privé de l'app, base SQLite avec migrations | P0 | Tests de migration et de suppression |
| NF-05 | Permissions demandées au moment de l'usage, refus géré proprement | P0 | Tests micro et fichiers refusés |
| NF-06 | Accessibilité : cibles ≥ 48 dp, lecteur d'écran, texte agrandi à 200 %, contraste AA (4,5:1) | P0 | Test de contraste automatisé + audit TalkBack/VoiceOver |
| NF-07 | Traitements lourds hors du fil UI, annulables, avec progression | P0 | Aucune image figée > 700 ms pendant OCR/ASR/traduction |
| NF-08 | Budget mémoire de pointe ≤ 1,2 Go sur appareil de référence moyen | P0 (provisoire) | Mesures RAM en phase 1 |
| NF-09 | Latence : traduction d'une phrase < 2 s, démarrage TTS < 1 s sur appareil de référence | P1 (provisoire) | Mesures en phase 1 |
| NF-10 | Taille de l'édition autonome à fixer après choix des modèles | P0 | Matrice modèles/tailles phase 0 |
| NF-11 | Licences compatibles avec la redistribution commerciale | P0 | Revue LEGAL-01, blocage sinon |
| NF-12 | Version affichée issue de la configuration de build | P0 | Test automatisé (fait dans le squelette) |
| NF-13 | Thèmes clair et sombre, interface en français puis anglais | P0 | Tests UI |
| NF-14 | Plateformes : Android arm64 et iPhone arm64, versions minimales fixées après tests matériels | P0 | Matrice de recette |

### 1.5 Hors périmètre V1

Compte utilisateur, synchronisation cloud, autres langues que FR/EN, édition de PDF, abonnement obligatoire.

### 1.6 Points ouverts à trancher (ne bloquent pas le squelette)

- **OCR en V1 ou V1.1 ?** S'il fait partie de la communication de lancement, il passe en P0.
- **Taille acceptable de l'édition autonome.** Les modèles TTS + ASR + traduction FR/EN peuvent représenter plusieurs centaines de Mo. À arbitrer en phase 0.
- **Site et contact de Chabane DEV** à afficher dans À propos (laissés vides et configurables tant qu'ils ne sont pas fournis).
- **Fichier source du logo.** Le PNG reçu contenait un faux damier de transparence dans ses coins. Il a été retiré (vrai fond transparent, logo inchangé) ; le fichier reçu est conservé dans `docs/brand/`. Un SVG d'origine resterait plus net aux grandes tailles.

---

## 2. Architecture Flutter

### 2.1 Choix et compromis

| Sujet | Choix | Pourquoi | Compromis |
|---|---|---|---|
| Base | Flutter (stable 3.47, Dart 3) | Une seule base Android/iOS, rendu fidèle à la maquette | Les moteurs IA passent par FFI ou canaux natifs |
| Navigation | `go_router` avec `StatefulShellRoute` | 4 onglets qui gardent leur état, routes profondes (lecteur, À propos), testable | Une dépendance de plus |
| État | `ChangeNotifier` + injection simple au démarrage | Zéro dépendance, surface d'audit réseau minimale | À réévaluer (Riverpod) quand les flux asynchrones des moteurs arriveront |
| Version | `package_info_plus` | Lit la version du build, aucune valeur codée en dur | — |
| Polices | Polices système pour l'instant | Pas de téléchargement de police (le paquet `google_fonts` contacte le réseau, il est exclu) | Une serif sous licence OFL sera embarquée en phase 2 |
| Base locale | SQLite via `sqflite` ou `drift` (à trancher en lot STORE-01) | Migrations, requêtes de recherche | `drift` ajoute de la génération de code |
| PDF | **Retenu : `pdfrx` 2.10 (MIT) + PDFium (BSD-3/Apache-2.0)** ; il peut ouvrir des URL, fonction jamais utilisée (et bloquée sur Android sans permission Internet) | Rendu + extraction de texte sur les deux plateformes | Licence et taille du binaire PDFium à vérifier |
| TTS | **Retenu : voix naturelles Piper Siwis (FR) et Alba (EN), int8 ≈ 18 Mo chacune, via `sherpa_onnx` 1.13 (Apache-2.0), lues avec `audioplayers` ; repli et choix possible sur les voix système hors ligne (`flutter_tts`)** | Voix plus naturelles, entièrement locales, choix de voix par langue | **À trancher en revue LEGAL-01 avant toute vente** : (1) sherpa-onnx embarque espeak-ng (GPL-3.0) pour la prononciation ; (2) les fiches des voix Siwis et Alba (CC-BY 4.0) indiquent un affinage depuis la voix « lessac », dont la licence d'origine est restrictive. Alternatives : voix système seules, ou modèle sous licence commerciale |
| ASR | **Retenu : `whisper_ggml` 2.8 (MIT) + whisper.cpp 1.9 (MIT), modèle Whisper « base » multilingue q5_1 (MIT, ≈ 57 Mo) embarqué dans l'application ; enregistrement par `record` 7 (BSD-3) en WAV 16 kHz** ; le paquet sait télécharger des modèles, fonction jamais appelée (et bloquée sur Android sans permission Internet) | Multilingue FR/EN, détection automatique de la langue | Conversion MP3/M4A par `ffmpeg_kit_flutter_new_min` (LGPL-3.0) sur Android/iOS : à valider en revue LEGAL-01 avant le Play Store ; Windows : WAV seulement ; vitesse et RAM sur Android moyen à mesurer |
| Traduction | Candidats : modèles Opus-MT / Bergamot (Marian) FR↔EN quantifiés, via CTranslate2 ou Bergamot | Compacts, deux directions, sans serveur | Licences (CC-BY pour certains modèles Opus-MT), segmentation des longs textes |
| OCR | iOS : Apple Vision. Android : ML Kit Text Recognition en version *bundled* ou Tesseract/PaddleOCR via ONNX | Vraiment hors ligne | ML Kit « non bundled » télécharge son modèle : à exclure |

Tous les moteurs sont à **valider en phase 1** par un prototype mesuré sur appareils physiques. Aucun n'est encore intégré.

### 2.2 Couches

```
presentation  →  domain  ←  data
                   ↑
               services (pdf, ocr, tts, asr, translation)  →  native_bridge
```

- **presentation** : écrans, widgets, thème, routeur. Ne connaît que les interfaces du domaine.
- **domain** : modèles (`LibraryItem`, `EngineStatus`…) et interfaces (`LibraryRepository`, `TtsService`…). Pur Dart, testable sans téléphone.
- **data** : implémentations des dépôts (aujourd'hui un dépôt d'exemple en mémoire, demain SQLite).
- **services** : un dossier par moteur, chacun derrière une interface du domaine. Aujourd'hui chaque service est une implémentation « non intégré » qui le dit explicitement.
- **native_bridge** : canaux de plateforme et FFI (à venir).
- **storage** : fichiers privés, caches, nettoyage (à venir).

### 2.3 Structure du projet

```
murmure/
├── lib/
│   ├── main.dart                     point d'entrée
│   ├── app.dart                      MaterialApp.router + thème
│   ├── core/
│   │   ├── theme/                    tokens couleurs, thèmes clair/sombre, modes lecteur
│   │   ├── router/                   routes go_router
│   │   └── app_scope.dart            injection des dépendances
│   ├── domain/
│   │   ├── models/                   LibraryItem, EngineStatus
│   │   └── services/                 interfaces des moteurs et du dépôt
│   ├── data/
│   │   └── sample/                   données d'EXEMPLE, marquées comme telles
│   ├── services/
│   │   ├── pdf/  ocr/  tts/  asr/  translation/
│   │   │                             implémentations « non intégré » pour l'instant
│   ├── storage/                      (lot STORE-01)
│   ├── native_bridge/                (lot phase 1)
│   └── presentation/
│       ├── shell/                    barre de navigation
│       ├── home/  library/  reader/  transcription/  translation/  settings/  about/
│       └── widgets/                  composants partagés (bandeau exemple, état vide, crédit)
├── assets/brand/chabane_dev.png      logo original, non modifié
├── docs/                             ce document
├── test/                             tests de navigation, À propos, contraste, honnêteté
└── android/ ios/
```

### 2.4 Traitements intensifs

OCR, ASR et traduction tourneront dans des isolats Dart ou des fils natifs, avec jeton d'annulation, progression, et un seul modèle lourd chargé à la fois pour tenir le budget mémoire. Les modèles sont chargés à la demande et libérés en arrière-plan.

### 2.5 Garde-fous de confidentialité déjà en place

- Le manifeste Android principal **retire** la permission `INTERNET` (`tools:node="remove"`), y compris si une bibliothèque tierce l'ajoute. Seuls les builds debug la gardent, car Flutter en a besoin pour le rechargement à chaud.
- Aucune dépendance réseau : `go_router` et `package_info_plus` seulement.
- Pas de police téléchargée, pas d'analytique.

Ces garde-fous ne remplacent pas l'audit réseau PRIV-01, qui reste à faire sur appareils.

---

## 3. Grille de risques techniques

Probabilité (P) et impact (I) notés de 1 à 3.

| # | Risque | P | I | Mitigation | Test de sortie |
|---|---|---|---|---|---|
| R1 | Taille de l'édition autonome trop lourde (modèles TTS + ASR + traduction) | 3 | 3 | Modèles quantifiés int8, une voix par langue en V1, Play Asset Delivery *install-time* et On-Demand Resources iOS embarqués | Taille mesurée et acceptée en phase 0 |
| R2 | Licence d'un modèle incompatible avec la vente (voix, Opus-MT, Whisper) | 2 | 3 | Matrice des licences avant intégration, alternatives listées par moteur | Revue LEGAL-01 signée |
| R3 | ASR trop lent ou trop gourmand sur Android moyen | 3 | 2 | Comparer whisper.cpp tiny/base/small et sherpa-onnx, traitement par segments | Facteur temps réel < 1 sur appareil de référence |
| R4 | Qualité des voix FR insuffisante | 2 | 3 | Écoute comparative de plusieurs voix, repli voix système si installées | Échantillons validés à l'écoute par rito |
| R5 | Traduction perd le sens sur les longs textes | 2 | 2 | Segmentation par phrase avec contexte, correction manuelle | Jeu de phrases de référence FR/EN |
| R6 | OCR Android non disponible hors ligne (ML Kit non bundled) | 2 | 2 | Utiliser la variante bundled ou un moteur ONNX embarqué | PDF scanné lu en mode avion |
| R7 | Lecture en arrière-plan coupée (iOS audio session, Android 14 services) | 2 | 3 | `audio_service` ou équivalent, service de premier plan `mediaPlayback` | Écran verrouillé 30 min sans coupure |
| R8 | Plantage mémoire en chargeant deux modèles | 2 | 3 | Un seul modèle lourd à la fois, déchargement, alertes basse mémoire | Mesures RAM + tests de stress |
| R9 | Fuite réseau via une bibliothèque tierce | 1 | 3 | Permission INTERNET retirée sur Android, audit de dépendances, capture réseau iOS | Audit PRIV-01 |
| R10 | Surlignage phrase/mot imprécis | 2 | 1 | Surlignage par phrase seulement si l'alignement est fiable | Validation visuelle P1 |
| R11 | Rendu ou extraction PDF défaillants sur fichiers difficiles | 2 | 2 | Corpus de PDF de test (chiffrés, corrompus, très longs) | Erreur explicite, jamais de plantage |
| R13 | Copie involontaire vers le cloud par les sauvegardes système (Auto Backup Android vers Google Drive, sauvegarde iCloud) | 2 | 3 | Android : sauvegarde désactivée dans le manifeste (fait). iOS : marquer le dossier documents « exclu de la sauvegarde » (à faire, code natif) | Vérification sur appareil |
| R12 | Logo source de qualité limitée (faux damier dans les coins) | 1 | 1 | Damier retiré par `tool/clean_logo.py`, source conservée ; SVG d'origine souhaitable | Logo net dans À propos |

---

## 4. Plan d'implémentation en incréments testables

| Lot | Contenu | Statut | Critère de validation |
|---|---|---|---|
| L0 | Squelette Flutter : navigation 4 onglets + lecteur + paramètres + À propos, thème clair/sombre, logo original, données d'exemple marquées, moteurs « non intégré » | **Fait (ce lot)** | `flutter analyze` propre et 17 tests verts (fait) ; build sur Android et iPhone réels (à faire) |
| L1 | Prototype de faisabilité : PDF texte, TTS FR/EN, ASR court, traduction d'une phrase, sur un Android et un iPhone physiques, mesures RAM/temps, audit réseau | À faire | Chaque fonction marche en mode avion avec mesures |
| L2 | STORE-01 : base SQLite, import réel, suppression, export des données | **Fait en partie** : base SQLite avec migrations, import PDF réel en stockage privé, suppression, favoris, dernière ouverture. Reste : export et suppression de toutes les données, menu Partager (F-02) | Import/suppression/restauration testés (fait, 6 tests) |
| L3 | PDF-01/02 : rendu, extraction, reprise de position | **Fait en partie** : rendu des pages (PDFium via pdfrx), nombre de pages à l'import, refus des PDF endommagés, page mémorisée et restaurée, texte de la page. Reste : recherche, signets, PDF protégés par mot de passe, test sur téléphone | Position restaurée après relance (testé sur la base) ; rendu vérifié dans un navigateur |
| L4 | TTS-01/02 : voix réelles, panneau audio, arrière-plan | À faire | Écran verrouillé, commandes système |
| L5 | ASR-01/02 : micro, import audio, transcription, export TXT | À faire | Fichiers de référence FR/EN |
| L6 | ~~TR-01/02 : traduction FR↔EN~~ annulée (≈ 200 Mo de modèles). Remplacée par l'onglet Découvrir : liens vers radios, livres et livres audio gratuits, ouverts dans le navigateur (l'appli garde zéro permission INTERNET) | Fait | Liens en https, testés |
| L7 | OCR-01, P1 (bilingue, surlignage, minuterie, SRT) | À faire | Selon tickets |
| L8 | QA-01, LEGAL-01, publication | À faire | Matrice de recette |

Le prompt maître demande que le lot L1 (faisabilité locale) passe **avant** tout investissement design supplémentaire. C'est la prochaine étape recommandée. Elle nécessite un Android et un iPhone physiques ; un Mac est nécessaire pour construire la version iOS.

---

## 5. Le squelette livré (lot L0)

### Implémenté

- Navigation : Accueil, Bibliothèque, Transcrire, Traduire (barre du bas), Lecteur ouvert depuis un document, Paramètres par l'icône engrenage, À propos depuis les Paramètres, licences tierces via la page de licences Flutter.
- Thème Murmure clair et sombre (ivoire #F3EFE7, vert foncé #344F49, vert pâle #D9E3DE, beige #E3D8CB) avec choix Système/Clair/Sombre dans les Paramètres (non persisté entre deux lancements pour l'instant).
- Modes de lecture clair, sombre et sépia dans le lecteur.
- Bibliothèque : recherche et filtres Tous/PDF/Audios/Transcriptions/Favoris.
- Traduction : saisie, permutation EN ⇄ FR.
- Logo Chabane DEV original : crédit discret sur l'Accueil et dans les Paramètres, logo plus grand dans À propos.
- Version lue depuis la configuration de build (`pubspec.yaml` → `package_info_plus`).
- Permission Android `INTERNET` retirée du build de production.

### Prototype (données d'exemple, clairement marquées)

- Les documents de la bibliothèque et le texte du lecteur sont des exemples. Un bandeau « Données d'exemple » est affiché sur chaque écran qui les utilise.

### Lot L2 (bibliothèque réelle)

- La bibliothèque est désormais réelle : base SQLite dans le dossier privé de l'application, versionnée avec migrations.
- « Importer PDF » ouvre le sélecteur de fichiers du système (sans permission), vérifie que le fichier est bien un PDF, puis le copie dans le stockage privé.
- Suppression avec confirmation (la ligne et le fichier), favoris et date de dernière ouverture persistés ; « Reprendre ma lecture » montre le dernier PDF ouvert.
- Les données d'exemple ne sont plus utilisées par l'application ; elles servent seulement aux tests.
- Ouvrir un PDF importé affiche honnêtement « Affichage des pages pas encore disponible » : le rendu arrive avec le moteur PDF.
- Android : sauvegarde cloud et transfert d'appareil désactivés pour les données de Murmure.

### Non fait (bouton désactivé ou message explicite dans l'app)

- Import PDF, rendu PDF, extraction de texte, OCR.
- Synthèse vocale, transcription, traduction : chaque moteur s'affiche « Non intégré » dans Paramètres → Moteurs locaux.
- Export et suppression de toutes les données, réception depuis le menu Partager, chiffrement, persistance des préférences d'apparence.
- Build Android (le SDK Android n'était pas téléchargeable dans l'environnement de travail) et build iOS (nécessite un Mac), tests sur appareils physiques, audit réseau.
- Vérification du manifeste Android fusionné : le retrait de `INTERNET` en release est en place mais reste à contrôler sur un vrai build.

### Vérifié

- `flutter analyze` : aucun problème.
- `flutter test` : 28 tests verts (dont 6 sur le moteur PDF réel : nombre de pages, texte avec accents, PDF endommagé, reprise de page) (dont 6 sur la bibliothèque réelle : import, refus d'un faux PDF, persistance après réouverture, suppression du fichier, parcours complet dans l'interface) (navigation des onglets, ouverture du lecteur, À propos avec logo et version du build, crédit discret, filtres et recherche, favoris, contraste AA des thèmes et des modes de lecture, bascule sombre, et des tests d'honnêteté : aucun moteur ne se déclare disponible, Traduire ne produit aucune fausse traduction, les données d'exemple sont signalées).
- Captures clair/sombre des 7 écrans dans `docs/captures/` (rendu web de contrôle, polices système du navigateur).

### Lancer le projet

```
flutter pub get
flutter test
flutter run            # appareil Android ou simulateur iOS connecté
flutter build apk --debug
```
