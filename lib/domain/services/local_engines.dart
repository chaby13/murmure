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

/// Contrat commun des moteurs embarqués (PDF, OCR, voix, transcription). Tous s'exécutent sur l'appareil, sans réseau.
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

/// Une voix installée sur l'appareil.
class TtsVoice {
  const TtsVoice({required this.name, required this.locale, this.gender});

  final String name;
  final String locale;

  /// « female », « male » ou null si inconnu.
  final String? gender;
}

abstract interface class TtsEngine implements LocalEngine {
  /// Voix hors ligne disponibles pour [language], la voix conseillée en
  /// premier.
  Future<List<TtsVoice>> voices(AppLanguage language);

  /// Prononce [text] et se termine quand la lecture est finie ou arrêtée.
  /// [rate] vaut 1 pour la vitesse normale. [voiceName] choisit une voix
  /// de [voices] ; sinon la voix conseillée est utilisée. Lève
  /// [TtsException] si aucune voix hors ligne n'existe pour [language].
  Future<void> speak(
    String text, {
    required AppLanguage language,
    double rate = 1,
    String? voiceName,
  });

  /// Prépare à l'avance la phrase suivante, si le moteur en tire profit.
  void prepare(
    String text, {
    required AppLanguage language,
    double rate = 1,
    String? voiceName,
  });

  Future<void> stop();
}

/// Erreur de transcription présentée telle quelle (fichier illisible…).
class AsrException implements Exception {
  const AsrException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class AsrEngine implements LocalEngine {
  /// Transcrit [audioPath]. [language] null = détection automatique.
  /// [vocabulary] : noms propres et mots rares à reconnaître (dictionnaire
  /// personnel). [onProgress] reçoit l'avancement de 0 à 100. Lève
  /// [AsrException] si le son ne peut pas être transcrit.
  Future<String> transcribe(
    String audioPath, {
    AppLanguage? language,
    List<String> vocabulary = const [],
    void Function(int percent)? onProgress,
  });
}
