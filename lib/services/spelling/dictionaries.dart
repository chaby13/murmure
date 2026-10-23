import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';

import '../../domain/models/app_language.dart';
import '../../domain/text/spell_checker.dart';

/// Charge à la demande les dictionnaires du correcteur, embarqués dans
/// l'application (`assets/dictionaries/<langue>.txt.gz`).
class SpellingDictionaries {
  SpellingDictionaries({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final _loaded = <AppLanguage, Future<SpellChecker>>{};

  static String assetFor(AppLanguage language) =>
      'assets/dictionaries/${language.code}.txt.gz';

  /// Le correcteur de [language]. Lève une exception si le dictionnaire
  /// manque dans cette version de l'application.
  Future<SpellChecker> of(AppLanguage language) =>
      _loaded[language] ??= _load(language).catchError((Object e) {
        _loaded.remove(language);
        throw e;
      });

  Future<SpellChecker> _load(AppLanguage language) async {
    final data = await _bundle.load(assetFor(language));
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    // Décompression et indexation hors du fil de l'interface.
    return Isolate.run(() {
      final text = utf8.decode(gzip.decode(bytes));
      final words = text.split('\n')..removeWhere((w) => w.isEmpty);
      return SpellChecker(language, words);
    });
  }
}
