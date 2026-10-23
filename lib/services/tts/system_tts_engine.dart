import 'dart:io';

import 'package:flutter_tts/flutter_tts.dart';

import '../../domain/models/app_language.dart';
import '../../domain/services/local_engines.dart';

/// Synthèse vocale avec les voix installées sur l'appareil (Android,
/// iPhone, Windows). Seules les voix qui fonctionnent sans réseau sont
/// utilisées : sur Android, les voix « réseau » sont écartées.
class SystemTtsEngine implements TtsEngine {
  SystemTtsEngine([FlutterTts? tts]) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  final Map<AppLanguage, Map<String, String>?> _voices = {};
  bool _ready = false;

  @override
  String get label => 'Synthèse vocale FR/EN (voix de l’appareil)';

  @override
  String get ticket => 'TTS-01';

  @override
  bool get isAvailable => true;

  @override
  Future<void> speak(
    String text, {
    required AppLanguage language,
    double rate = 1,
  }) async {
    if (!_ready) {
      await _tts.awaitSpeakCompletion(true);
      _ready = true;
    }
    final voice = await _offlineVoice(language);
    if (voice == null) {
      throw TtsException(
        'Aucune voix ${language == AppLanguage.fr ? 'française' : 'anglaise'} '
        'hors ligne n’est installée sur cet appareil. Ajoutez-en une dans '
        'les réglages de synthèse vocale du système.',
      );
    }
    await _tts.setVoice(voice);
    await _tts.setSpeechRate(_platformRate(rate));
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }

  Future<Map<String, String>?> _offlineVoice(AppLanguage language) async {
    if (_voices.containsKey(language)) return _voices[language];
    final raw = await _tts.getVoices;
    Map<String, String>? found;
    if (raw is List) {
      for (final entry in raw) {
        if (entry is! Map) continue;
        final locale = '${entry['locale'] ?? ''}'.toLowerCase();
        final name = '${entry['name'] ?? ''}';
        final needsNetwork = '${entry['network_required'] ?? '0'}' == '1';
        if (name.isEmpty || needsNetwork) continue;
        if (!locale.startsWith(language.code)) continue;
        found = {'name': name, 'locale': '${entry['locale']}'};
        // Préfère la variante de France ou des États-Unis.
        if (locale.contains(language == AppLanguage.fr ? 'fr' : 'us')) break;
      }
    }
    _voices[language] = found;
    return found;
  }

  /// La vitesse « normale » n'a pas la même valeur selon la plateforme.
  static double _platformRate(double rate) {
    if (Platform.isIOS || Platform.isMacOS) return (0.5 * rate).clamp(0.1, 1.0);
    return rate.clamp(0.25, 3.0);
  }
}
