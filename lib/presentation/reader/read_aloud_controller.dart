import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../domain/models/app_language.dart';
import '../../domain/services/local_engines.dart';
import '../../domain/text/reading_text.dart';

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
  }) : _page = startPage;

  final TtsEngine tts;
  final PdfEngine pdf;
  final String filePath;
  final int pageCount;

  /// Appelé quand la lecture passe à une autre page, pour que le lecteur
  /// l'affiche.
  final void Function(int page)? onPageChanged;

  ReadAloudStatus _status = ReadAloudStatus.idle;
  int _page;
  List<String>? _sentences;
  int _index = 0;
  AppLanguage _detected = AppLanguage.fr;
  AppLanguage? _languageOverride;
  double _speed = 1;
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

  String? get currentSentence {
    final sentences = _sentences;
    if (sentences == null || _index >= sentences.length) return null;
    return sentences[_index];
  }

  Future<void> play() async {
    if (_status == ReadAloudStatus.finished) {
      _goTo(1);
    }
    final session = ++_session;
    _error = null;
    try {
      while (session == _session) {
        var sentences = _sentences;
        if (sentences == null) {
          _set(ReadAloudStatus.loading);
          final text = await pdf.extractPageText(filePath, _page);
          if (session != _session) return;
          sentences = _sentences = splitSentences(text);
          _detected = detectLanguage(text) ?? _detected;
          _index = 0;
        }
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
        await tts.speak(sentences[_index], language: language, rate: _speed);
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
  Future<void> skip(int delta) async {
    final wasActive = isActive;
    _session++;
    await tts.stop();
    final count = _sentences?.length ?? 0;
    _index = count == 0 ? 0 : (_index + delta).clamp(0, max(0, count - 1));
    _notify();
    if (wasActive) await play();
  }

  Future<void> setSpeed(double speed) async {
    _speed = speed;
    await _restartIfActive();
  }

  /// null = détection automatique de la langue du texte.
  Future<void> setLanguage(AppLanguage? language) async {
    _languageOverride = language;
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

  void _goTo(int page) {
    _page = page;
    _sentences = null;
    _index = 0;
  }

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
