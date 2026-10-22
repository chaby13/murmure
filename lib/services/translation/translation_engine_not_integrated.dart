import '../../domain/models/app_language.dart';
import '../../domain/services/local_engines.dart';

/// Emplacement réservé à la traduction locale FR ⇄ EN (tickets TR-01/TR-02).
/// Aucun service distant ne doit jamais servir de secours silencieux.
class TranslationEngineNotIntegrated implements TranslationEngine {
  const TranslationEngineNotIntegrated();

  @override
  String get label => 'Traduction FR ⇄ EN';

  @override
  String get ticket => 'TR-01';

  @override
  bool get isAvailable => false;

  @override
  Future<String> translate(
    String text, {
    required AppLanguage from,
    required AppLanguage to,
  }) => throw EngineNotIntegratedException(label, ticket);
}
