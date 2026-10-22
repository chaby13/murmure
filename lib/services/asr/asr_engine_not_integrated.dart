import '../../domain/models/app_language.dart';
import '../../domain/services/local_engines.dart';

/// Emplacement réservé à la transcription locale (ticket ASR-01).
class AsrEngineNotIntegrated implements AsrEngine {
  const AsrEngineNotIntegrated();

  @override
  String get label => 'Transcription FR/EN';

  @override
  String get ticket => 'ASR-01';

  @override
  bool get isAvailable => false;

  @override
  Future<String> transcribe(String audioPath, {AppLanguage? language}) =>
      throw EngineNotIntegratedException(label, ticket);
}
