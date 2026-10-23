import '../models/app_language.dart';

/// Levée quand une fonction dépend d'un moteur local qui n'est pas encore
/// intégré. Murmure ne simule jamais un résultat à la place.
class EngineNotIntegratedException implements Exception {
  const EngineNotIntegratedException(this.engine, this.ticket);

  final String engine;
  final String ticket;

  @override
  String toString() => '$engine : moteur local non intégré (ticket $ticket).';
}

/// Contrat commun des moteurs embarqués (PDF, OCR, voix, transcription,
/// traduction). Tous s'exécutent sur l'appareil, sans réseau.
abstract interface class LocalEngine {
  /// Nom affiché dans Paramètres → Moteurs locaux.
  String get label;

  /// Ticket du backlog qui livrera ce moteur.
  String get ticket;

  bool get isAvailable;
}

/// Erreur d'ouverture d'un PDF (endommagé, protégé par mot de passe…).
class PdfOpenException implements Exception {
  const PdfOpenException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class PdfEngine implements LocalEngine {
  /// Nombre de pages. Lève [PdfOpenException] si le fichier ne s'ouvre pas.
  Future<int> pageCount(String filePath);

  /// Texte de la page [pageNumber] (à partir de 1). Chaîne vide pour une
  /// page sans texte, par exemple une page scannée.
  Future<String> extractPageText(String filePath, int pageNumber);
}

abstract interface class OcrEngine implements LocalEngine {
  Future<String> recognizePage(String filePath, int pageIndex);
}

/// Erreur de synthèse vocale présentée telle quelle (voix manquante…).
class TtsException implements Exception {
  const TtsException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class TtsEngine implements LocalEngine {
  /// Prononce [text] et se termine quand la lecture est finie ou arrêtée.
  /// [rate] vaut 1 pour la vitesse normale. Lève [TtsException] si aucune
  /// voix hors ligne n'existe pour [language].
  Future<void> speak(
    String text, {
    required AppLanguage language,
    double rate = 1,
  });

  Future<void> stop();
}

abstract interface class AsrEngine implements LocalEngine {
  Future<String> transcribe(String audioPath, {AppLanguage? language});
}

abstract interface class TranslationEngine implements LocalEngine {
  Future<String> translate(
    String text, {
    required AppLanguage from,
    required AppLanguage to,
  });
}
