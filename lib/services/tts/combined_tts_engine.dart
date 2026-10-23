import '../../domain/models/app_language.dart';
import '../../domain/services/local_engines.dart';
import 'piper_tts_engine.dart';

/// Voix naturelles embarquées en premier, puis voix de l'appareil.
class CombinedTtsEngine implements TtsEngine {
  CombinedTtsEngine({required this.embedded, required this.system});

  final PiperTtsEngine embedded;
  final TtsEngine system;
  TtsEngine? _last;

  @override
  String get label => 'Synthèse vocale FR/EN (voix naturelles et appareil)';

  @override
  String get ticket => 'TTS-01';

  @override
  bool get isAvailable => true;

  @override
  Future<List<TtsVoice>> voices(AppLanguage language) async {
    final List<TtsVoice> fromDevice;
    try {
      fromDevice = await system.voices(language);
    } catch (_) {
      return embedded.voices(language);
    }
    return [...await embedded.voices(language), ...fromDevice];
  }

  /// Voix de l'appareil seulement si elle est choisie explicitement.
  TtsEngine _engineFor(AppLanguage language, String? voiceName) {
    if (voiceName == null || embedded.owns(voiceName)) return embedded;
    return system;
  }

  @override
  void prepare(
    String text, {
    required AppLanguage language,
    double rate = 1,
    String? voiceName,
  }) {
    if (_engineFor(language, voiceName) == embedded) {
      embedded.prepare(
        text,
        language: language,
        rate: rate,
        voiceName: voiceName,
      );
    }
  }

  @override
  Future<void> speak(
    String text, {
    required AppLanguage language,
    double rate = 1,
    String? voiceName,
  }) async {
    var engine = _engineFor(language, voiceName);
    if (engine == embedded && (await embedded.voices(language)).isEmpty) {
      engine = system;
    }
    _last = engine;
    await engine.speak(
      text,
      language: language,
      rate: rate,
      voiceName: voiceName,
    );
  }

  @override
  Future<void> stop() async {
    await (_last ?? embedded).stop();
  }
}
