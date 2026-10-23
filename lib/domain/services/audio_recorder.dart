/// Erreur d'enregistrement présentée telle quelle (micro refusé…).
class RecorderException implements Exception {
  const RecorderException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Enregistrement au microphone, en WAV 16 kHz mono (le format attendu par
/// la transcription).
abstract interface class AudioRecorderService {
  bool get isAvailable;

  /// Demande l'accès au micro si besoin, puis commence à enregistrer dans
  /// un fichier temporaire. Lève [RecorderException] si le micro est refusé.
  Future<void> start();

  /// Arrête et renvoie le fichier enregistré, ou null si rien n'a été
  /// enregistré.
  Future<String?> stop();

  /// Arrête et efface l'enregistrement en cours.
  Future<void> cancel();
}

/// Plateforme sans micro pris en charge (démonstration web, tests).
class NoAudioRecorder implements AudioRecorderService {
  const NoAudioRecorder();

  @override
  bool get isAvailable => false;

  @override
  Future<void> start() => throw const RecorderException(
    'L’enregistrement n’est pas disponible sur cet appareil.',
  );

  @override
  Future<String?> stop() async => null;

  @override
  Future<void> cancel() async {}
}
