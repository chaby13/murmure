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

abstract interface class PdfEngine implements LocalEngine {
  Future<String> extractPageText(String filePath, int pageIndex);
}

abstract interface class OcrEngine implements LocalEngine {
  Future<String> recognizePage(String filePath, int pageIndex);
}

abstract interface class TtsEngine implements LocalEngine {
  Future<void> speak(String text, {required AppLanguage language});

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
