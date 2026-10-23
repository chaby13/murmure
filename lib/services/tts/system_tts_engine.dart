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
  final Map<AppLanguage, List<TtsVoice>> _voices = {};
  bool _ready = false;
  String? _currentVoice;
  double? _currentRate;

  @override
  String get label => 'Synthèse vocale FR/EN (voix de l’appareil)';

  @override
  String get ticket => 'TTS-01';

  @override
  bool get isAvailable => true;

  @override
  Future<List<TtsVoice>> voices(AppLanguage language) async {
    final cached = _voices[language];
    if (cached != null) return cached;
    final raw = await _tts.getVoices;
    final found = <TtsVoice>[];
    final seen = <String>{};
    if (raw is List) {
      for (final entry in raw) {
        if (entry is! Map) continue;
        final locale = '${entry['locale'] ?? ''}';
        final name = '${entry['name'] ?? ''}';
        final needsNetwork = '${entry['network_required'] ?? '0'}' == '1';
        if (name.isEmpty || needsNetwork || !seen.add(name)) continue;
        if (!locale.toLowerCase().startsWith(language.code)) continue;
        final gender = '${entry['gender'] ?? ''}'.toLowerCase();
        found.add(
          TtsVoice(
            name: name,
            locale: locale,
            gender: gender == 'female' || gender == 'male' ? gender : null,
          ),
        );
      }
    }
    // Variante de France ou des États-Unis en premier.
    final preferred = language == AppLanguage.fr ? 'fr-fr' : 'en-us';
    int rank(TtsVoice v) =>
        v.locale.toLowerCase().replaceAll('_', '-').startsWith(preferred)
        ? 0
        : 1;
    found.sort((a, b) => rank(a).compareTo(rank(b)));
    return _voices[language] = found;
  }

  @override
  Future<void> speak(
    String text, {
    required AppLanguage language,
    double rate = 1,
    String? voiceName,
  }) async {
    if (!_ready) {
      await _tts.awaitSpeakCompletion(true);
      _ready = true;
    }
    final available = await voices(language);
    if (available.isEmpty) {
      throw TtsException(
        'Aucune voix ${language == AppLanguage.fr ? 'française' : 'anglaise'} '
        'hors ligne n’est installée sur cet appareil. Ajoutez-en une dans '
        'les réglages de synthèse vocale du système.',
      );
    }
    final voice = available.firstWhere(
      (v) => v.name == voiceName,
      orElse: () => available.first,
    );
    if (voice.name != _currentVoice) {
      await _tts.setVoice({'name': voice.name, 'locale': voice.locale});
      _currentVoice = voice.name;
    }
    final platformRate = _platformRate(rate);
    if (platformRate != _currentRate) {
      await _tts.setSpeechRate(platformRate);
      _currentRate = platformRate;
    }
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }

  /// Pour flutter_tts, la vitesse normale vaut 0,5 sur toutes les
  /// plateformes (Android la double, Windows lui ajoute 0,5).
  static double _platformRate(double rate) {
    final max = Platform.isIOS || Platform.isMacOS ? 1.0 : 1.5;
    return (0.5 * rate).clamp(0.1, max);
  }
}
