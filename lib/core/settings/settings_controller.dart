import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/models/app_language.dart';
import '../../domain/models/read_aloud_preferences.dart';
import '../theme/murmure_colors.dart';

/// Préférences de l'utilisateur, enregistrées dans un petit fichier JSON
/// du dossier privé de l'application quand [file] est fourni.
class SettingsController extends ChangeNotifier {
  SettingsController({this.file});

  /// Vitesse de lecture proposée par défaut : un peu plus posée que la
  /// vitesse normale de l'appareil.
  static const defaultReadSpeed = 0.9;

  final File? file;
  Future<void> _writing = Future.value();

  /// Se termine quand les derniers changements sont écrits sur le disque.
  Future<void> get saved => _writing;
  ThemeMode _themeMode = ThemeMode.system;
  ReaderMode _readerMode = ReaderMode.light;
  ReadAloudPreferences _readAloud = const ReadAloudPreferences(
    speed: defaultReadSpeed,
  );

  /// Relit les préférences enregistrées. Un fichier absent ou abîmé donne
  /// les réglages par défaut.
  static Future<SettingsController> load(File file) async {
    final settings = SettingsController(file: file);
    try {
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString());
        if (json is Map<String, dynamic>) settings._apply(json);
      }
    } catch (_) {}
    return settings;
  }

  List<String> _personalWords = const [];

  /// Dictionnaire personnel : mots acceptés par le correcteur et donnés à
  /// la transcription (noms propres, vocabulaire de métier).
  List<String> get personalWords => _personalWords;

  void addPersonalWord(String word) {
    final w = word.trim();
    if (w.isEmpty ||
        _personalWords.any((x) => x.toLowerCase() == w.toLowerCase())) {
      return;
    }
    _personalWords = [..._personalWords, w]
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    _changed();
  }

  void removePersonalWord(String word) {
    _personalWords = [
      for (final w in _personalWords)
        if (w != word) w,
    ];
    _changed();
  }

  ThemeMode get themeMode => _themeMode;
  ReaderMode get readerMode => _readerMode;
  ReadAloudPreferences get readAloud => _readAloud;

  set themeMode(ThemeMode value) {
    if (value == _themeMode) return;
    _themeMode = value;
    _changed();
  }

  set readerMode(ReaderMode value) {
    if (value == _readerMode) return;
    _readerMode = value;
    _changed();
  }

  set readAloud(ReadAloudPreferences value) {
    _readAloud = value;
    _changed();
  }

  void _apply(Map<String, dynamic> json) {
    T? byName<T extends Enum>(List<T> values, Object? name) {
      for (final v in values) {
        if (v.name == name) return v;
      }
      return null;
    }

    _themeMode = byName(ThemeMode.values, json['theme']) ?? _themeMode;
    _readerMode = byName(ReaderMode.values, json['reader']) ?? _readerMode;
    final words = json['personalWords'];
    if (words is List) {
      _personalWords = [
        for (final w in words)
          if (w is String && w.trim().isNotEmpty) w.trim(),
      ];
    }
    final speed = json['readSpeed'];
    final voices = json['voices'];
    _readAloud = ReadAloudPreferences(
      speed: speed is num ? speed.toDouble() : defaultReadSpeed,
      voices: {
        if (voices is Map)
          for (final entry in voices.entries)
            ?byName(AppLanguage.values, entry.key): '${entry.value}',
      },
    );
  }

  void _changed() {
    notifyListeners();
    final file = this.file;
    if (file == null) return;
    final json = {
      'theme': _themeMode.name,
      'reader': _readerMode.name,
      'readSpeed': _readAloud.speed,
      'voices': {
        for (final e in _readAloud.voices.entries) e.key.name: e.value,
      },
      'personalWords': _personalWords,
    };
    // Écritures l'une après l'autre : la dernière gagne toujours.
    final content = jsonEncode(json);
    _writing = _writing
        .then((_) => file.writeAsString(content, flush: true))
        .then((_) {}, onError: (_) {});
  }
}
