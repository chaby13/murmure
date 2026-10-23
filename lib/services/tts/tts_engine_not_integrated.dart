import '../../domain/models/app_language.dart';
import '../../domain/services/local_engines.dart';

/// Emplacement réservé à la synthèse vocale locale (ticket TTS-01).
class TtsEngineNotIntegrated implements TtsEngine {
  const TtsEngineNotIntegrated();

  @override
  String get label => 'Synthèse vocale FR/EN';

  @override
  String get ticket => 'TTS-01';

  @override
  bool get isAvailable => false;

  @override
  Future<List<TtsVoice>> voices(AppLanguage language) async => const [];

  @override
  Future<void> speak(
    String text, {
    required AppLanguage language,
    double rate = 1,
    String? voiceName,
  }) => throw EngineNotIntegratedException(label, ticket);

  @override
  Future<void> stop() async {}
}
