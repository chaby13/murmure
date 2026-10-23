import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../domain/models/app_language.dart';
import '../../domain/models/read_aloud_preferences.dart';
import '../../domain/services/local_engines.dart';
import '../../domain/text/reading_text.dart';

export '../../domain/models/read_aloud_preferences.dart';

enum ReadAloudStatus { idle, loading, playing, paused, finished }

/// Lit un PDF à voix haute, phrase par phrase et page après page.
class ReadAloudController extends ChangeNotifier {
  ReadAloudController({
    required this.tts,
    required this.pdf,
    required this.filePath,
    required this.pageCount,
    required int startPage,
    this.onPageChanged,
    ReadAloudPreferences preferences = const ReadAloudPreferences(),
    this.onPreferencesChanged,
  }) : _page = startPage,
       _speed = preferences.speed,
       _voiceNames = {...preferences.voices};

  final TtsEngine tts;
  final PdfEngine pdf;
  final String filePath;
  final int pageCount;

  /// Appelé quand la lecture passe à une autre page, pour que le lecteur
  /// l'affiche.
  final void Function(int page)? onPageChanged;

  /// Appelé quand la vitesse ou la voix change, pour la retenir.
  final void Function(ReadAloudPreferences preferences)? onPreferencesChanged;

  ReadAloudStatus _status = ReadAloudStatus.idle;
  int _page;
  List<String>? _sentences;

  /// Indice de la première phrase de chaque paragraphe de la page.
  List<int> _paragraphStarts = const [];
  int _index = 0;
  AppLanguage _detected = AppLanguage.fr;
  AppLanguage? _languageOverride;
  double _speed;
  final Map<AppLanguage, String> _voiceNames;
  final Map<AppLanguage, List<TtsVoice>> _voices = {};
  String? _error;

  /// Incrémenté à chaque arrêt : une boucle de lecture plus ancienne
  /// s'interrompt d'elle-même.
  int _session = 0;
  bool _disposed = false;

  ReadAloudStatus get status => _status;
  int get page => _page;
  double get speed => _speed;
  String? get error => _error;
  AppLanguage get language => _languageOverride ?? _detected;
  bool get isLanguageAuto => _languageOverride == null;
  bool get isActive =>
      _status == ReadAloudStatus.playing || _status == ReadAloudStatus.loading;

  /// Voix disponibles pour la langue de lecture (vide tant qu'elles ne sont
  /// pas chargées, voir [loadVoices]).
  List<TtsVoice> get voices => _voices[language] ?? const [];

  /// Voix utilisée pour la langue de lecture.
  String? get voiceName {
    final available = voices;
    final chosen = _voiceNames[language];
    if (chosen != null && available.any((v) => v.name == chosen)) {
      return chosen;
    }
    return available.isEmpty ? null : available.first.name;
  }

  String? get currentSentence {
    final sentences = _sentences;
    if (sentences == null || _index >= sentences.length) return null;
    return sentences[_index];
  }

  /// Charge la liste des voix de l'appareil pour les deux langues.
  Future<void> loadVoices() async {
    for (final language in AppLanguage.values) {
      try {
        _voices[language] = await tts.voices(language);
      } catch (_) {
        _voices[language] = const [];
      }
    }
    _notify();
  }

  Future<void> play() async {
    if (_status == ReadAloudStatus.finished) {
      _goTo(1);
      onPageChanged?.call(1);
    }
    final session = ++_session;
    _error = null;
    try {
      while (session == _session) {
        if (_sentences == null) {
          _set(ReadAloudStatus.loading);
          await _load();
          if (session != _session) return;
        }
        final sentences = _sentences!;
        if (_index >= sentences.length) {
          if (_page >= pageCount) {
            _index = 0;
            _set(ReadAloudStatus.finished);
            return;
          }
          _goTo(_page + 1);
          onPageChanged?.call(_page);
          continue;
        }
        _set(ReadAloudStatus.playing);
        await tts.speak(
          sentences[_index],
          language: language,
          rate: _speed,
          voiceName: voiceName,
        );
        if (session != _session) return;
        _index++;
      }
    } catch (e) {
      if (session != _session) return;
      _error = e is TtsException || e is PdfOpenException
          ? e.toString()
          : 'La lecture à voix haute a échoué.';
      _set(ReadAloudStatus.idle);
    }
  }

  Future<void> pause() async {
    _session++;
    _set(ReadAloudStatus.paused);
    await tts.stop();
  }

  Future<void> togglePlay() => isActive ? pause() : play();

  /// Passe à la phrase précédente ([delta] = -1) ou suivante (+1).
  Future<void> skip(int delta) => _jump(() async {
    final count = _sentences?.length ?? 0;
    _index = count == 0 ? 0 : (_index + delta).clamp(0, max(0, count - 1));
  });

  /// Paragraphe précédent ([delta] = -1) ou suivant (+1). Au bout de la
  /// page, passe à la page voisine. « Précédent » revient d'abord au début
  /// du paragraphe en cours.
  Future<void> skipParagraph(int delta) => _jump(() async {
    if (_sentences == null) await _load();
    final starts = _paragraphStarts;
    var current = 0;
    for (var p = 0; p < starts.length; p++) {
      if (starts[p] <= _index) current = p;
    }
    if (delta > 0) {
      if (current + 1 < starts.length) {
        _index = starts[current + 1];
      } else if (_page < pageCount) {
        _goTo(_page + 1);
        onPageChanged?.call(_page);
      }
    } else {
      if (starts.isNotEmpty && _index > starts[current]) {
        _index = starts[current];
      } else if (current > 0) {
        _index = starts[current - 1];
      } else if (_page > 1) {
        // Dernier paragraphe de la page précédente.
        _goTo(_page - 1);
        onPageChanged?.call(_page);
        await _load();
        _index = _paragraphStarts.isEmpty ? 0 : _paragraphStarts.last;
      }
    }
  });

  /// Page précédente ([delta] = -1) ou suivante (+1), lue depuis le début.
  Future<void> skipPage(int delta) => _jump(() async {
    final target = (_page + delta).clamp(1, pageCount);
    if (target == _page) {
      _index = 0;
      return;
    }
    _goTo(target);
    onPageChanged?.call(_page);
  });

  /// Lit à partir de la phrase [sentenceIndex] de la page [page].
  Future<void> playFrom(int page, int sentenceIndex) async {
    _session++;
    await tts.stop();
    if (page != _page || _sentences == null) {
      _goTo(page.clamp(1, pageCount));
      await _load();
    }
    _index = sentenceIndex.clamp(0, max(0, (_sentences?.length ?? 1) - 1));
    if (_status == ReadAloudStatus.finished) _status = ReadAloudStatus.idle;
    await play();
  }

  Future<void> setSpeed(double speed) async {
    _speed = speed;
    _savePreferences();
    await _restartIfActive();
  }

  /// null = détection automatique de la langue du texte.
  Future<void> setLanguage(AppLanguage? language) async {
    _languageOverride = language;
    await _restartIfActive();
  }

  /// Choisit la voix de la langue de lecture.
  Future<void> setVoice(String name) async {
    _voiceNames[language] = name;
    _savePreferences();
    await _restartIfActive();
  }

  /// L'utilisateur a fait défiler le document : la lecture repartira de la
  /// page visible si elle n'est pas en cours.
  void followPage(int page) {
    if (isActive || page == _page) return;
    _goTo(page);
    if (_status == ReadAloudStatus.finished) _status = ReadAloudStatus.idle;
    _notify();
  }

  Future<void> _load() async {
    final text = await pdf.extractPageText(filePath, _page);
    final paragraphs = splitParagraphs(text);
    final starts = <int>[];
    final sentences = <String>[];
    for (final paragraph in paragraphs) {
      starts.add(sentences.length);
      sentences.addAll(paragraph);
    }
    _sentences = sentences;
    _paragraphStarts = starts;
    _detected = detectLanguage(text) ?? _detected;
    _index = 0;
  }

  /// Arrête la voix, déplace la position, puis reprend si on lisait.
  Future<void> _jump(Future<void> Function() move) async {
    final wasActive = isActive;
    _session++;
    await tts.stop();
    try {
      await move();
    } catch (e) {
      _error = e is PdfOpenException ? e.toString() : 'Page illisible.';
    }
    if (_status == ReadAloudStatus.finished) _status = ReadAloudStatus.paused;
    _notify();
    if (wasActive) await play();
  }

  void _goTo(int page) {
    _page = page;
    _sentences = null;
    _paragraphStarts = const [];
    _index = 0;
  }

  void _savePreferences() => onPreferencesChanged?.call(
    ReadAloudPreferences(speed: _speed, voices: Map.of(_voiceNames)),
  );

  Future<void> _restartIfActive() async {
    if (!isActive) {
      _notify();
      return;
    }
    _session++;
    await tts.stop();
    await play();
  }

  void _set(ReadAloudStatus status) {
    _status = status;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _session++;
    tts.stop();
    super.dispose();
  }
}
