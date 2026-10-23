import 'package:flutter/foundation.dart';

/// Crédits des modèles embarqués, affichés dans la page des licences
/// (Paramètres → À propos). Les licences CC-BY demandent cette mention.
void registerEmbeddedLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      ['Voix Siwis (français)'],
      'Voix de synthèse Piper « fr_FR-siwis-medium », entraînée sur le jeu '
      'de données SIWIS (https://datashare.is.ed.ac.uk/handle/10283/2353), '
      'licence Creative Commons Attribution 4.0 (CC-BY 4.0). Version '
      'quantifiée int8 publiée par le projet sherpa-onnx.',
    );
    yield const LicenseEntryWithLineBreaks(
      ['Voix Alba (anglais)'],
      'Voix de synthèse Piper « en_GB-alba-medium », entraînée sur le jeu '
      'de données https://datashare.ed.ac.uk/handle/10283/3270, licence '
      'Creative Commons Attribution 4.0 (CC-BY 4.0). Version quantifiée '
      'int8 publiée par le projet sherpa-onnx.',
    );
    yield const LicenseEntryWithLineBreaks(
      ['Modèle Whisper base'],
      'Modèle de reconnaissance vocale Whisper « base » d’OpenAI, licence '
      'MIT, converti et quantifié (q5_1) pour whisper.cpp.',
    );
  });
}
