import 'dart:math';

import '../models/app_language.dart';

/// Un mot du texte et sa position.
class WordSpan {
  const WordSpan(this.start, this.end, this.text);

  final int start;
  final int end;
  final String text;

  @override
  bool operator ==(Object other) =>
      other is WordSpan && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

final _wordPattern = RegExp(
  r"[\p{L}\p{M}](?:[\p{L}\p{M}]|['’\-](?=[\p{L}\p{M}]))*",
  unicode: true,
);

/// Les mots de [text], avec apostrophes et traits d'union intérieurs
/// (« aujourd'hui », « peut-être »).
Iterable<WordSpan> wordsOf(String text) sync* {
  for (final m in _wordPattern.allMatches(text)) {
    yield WordSpan(m.start, m.end, m[0]!);
  }
}

/// Correcteur d'orthographe hors ligne : une liste de mots (toutes les
/// formes fléchies), classée du plus courant au plus rare.
class SpellChecker {
  SpellChecker(this.language, List<String> rankedWords)
    : _rank = {
        for (var i = rankedWords.length - 1; i >= 0; i--) rankedWords[i]: i,
      } {
    // Index des mots par « squelette » (sans accents ni lettres doublées),
    // seulement quand le squelette diffère du mot.
    for (final word in rankedWords) {
      final lower = word.toLowerCase();
      if (lower != word) continue;
      final key = skeleton(word);
      if (key == word) continue;
      final existing = _bySkeleton[key];
      _bySkeleton[key] = existing == null ? word : '$existing|$word';
    }
  }

  final AppLanguage language;
  final Map<String, int> _rank;
  final Map<String, String> _bySkeleton = {};

  /// Forme simplifiée d'un mot : sans accents, ligatures dépliées, lettres
  /// doublées réduites à une. « Développement » et « developement » ont le
  /// même squelette.
  static String skeleton(String word) {
    final buffer = StringBuffer();
    var previous = '';
    for (final c in _stripAccents(word.toLowerCase()).split('')) {
      if (c != previous) buffer.write(c);
      previous = c;
    }
    return buffer.toString();
  }

  /// Mots ajoutés par l'utilisateur, acceptés quelle que soit la casse.
  Set<String> personal = {};

  int get size => _rank.length;

  static const _letters = {
    AppLanguage.fr: 'abcdefghijklmnopqrstuvwxyzàâäçéèêëîïôöùûüÿœæ\'-',
    AppLanguage.en: "abcdefghijklmnopqrstuvwxyz'-",
  };

  bool _known(String word) {
    if (_rank.containsKey(word)) return true;
    final lower = word.toLowerCase();
    if (personal.contains(lower)) return true;
    // Début de phrase ou mot écrit en capitales.
    if (word != lower && _rank.containsKey(lower)) return true;
    if (word.length > 1 && word == word.toUpperCase()) {
      final capitalized = lower[0].toUpperCase() + lower.substring(1);
      if (_rank.containsKey(capitalized)) return true;
    }
    return false;
  }

  /// Vrai si [word] est correctement écrit.
  bool isCorrect(String word) {
    final w = word.replaceAll('’', "'");
    if (_known(w)) return true;
    // Élisions : l'arbre, qu'il, jusqu'ici…
    final apostrophe = w.indexOf("'");
    if (apostrophe > 0 && apostrophe < w.length - 1) {
      final prefix = w.substring(0, apostrophe + 1);
      if (_known(prefix) && isCorrect(w.substring(apostrophe + 1))) {
        return true;
      }
      if (language == AppLanguage.en) {
        // Possessif : Murmure's.
        if (w.endsWith("'s") && _known(w.substring(0, w.length - 2))) {
          return true;
        }
      }
    }
    // Mots composés : dit-il, va-t-on, rendez-vous inconnus en bloc.
    if (w.contains('-')) {
      final parts = w.split('-').where((p) => p.isNotEmpty).toList();
      if (parts.isNotEmpty &&
          parts.every((p) => p == 't' || p.length == 1 || isCorrect(p))) {
        return true;
      }
    }
    return false;
  }

  /// Mots mal écrits de [text].
  List<WordSpan> misspelled(String text) => [
    for (final word in wordsOf(text))
      if (!isCorrect(word.text)) word,
  ];

  /// Jusqu'à [max] corrections pour [word], les plus probables d'abord.
  List<String> suggest(String word, {int limit = 5}) {
    final original = word.replaceAll('’', "'");
    final lower = original.toLowerCase();
    final letters = _letters[language]!;
    final key = skeleton(lower);
    // Score : rareté du mot (logarithme du rang) plus un coût par faute.
    // Une erreur d'accent ou de lettre doublée coûte peu.
    final found = <String, double>{};

    void consider(String candidate, double cost) {
      final rank = _rank[candidate];
      if (rank == null) return;
      final score = log(rank + 2) + cost * 3.5;
      final previous = found[candidate];
      if (previous == null || score < previous) found[candidate] = score;
    }

    void considerSkeleton(String k, double cost) {
      final words = _bySkeleton[k];
      if (words != null) {
        for (final w in words.split('|')) {
          consider(w, cost);
        }
      }
      consider(k, cost);
    }

    // Accents, lettres doublées et ligatures : coeur → cœur,
    // developement → développement, apeller → appeler.
    considerSkeleton(key, 0.5);
    final first = _edits(lower, letters).toSet();
    for (final c in first) {
      consider(c, skeleton(c) == key ? 0.5 : 1);
    }
    // Une faute plus une erreur d'accent ou de lettre doublée.
    for (final k in _edits(key, letters).toSet()) {
      considerSkeleton(k, 1.5);
    }
    if (found.length < limit && lower.length <= 12) {
      for (final c in first) {
        for (final c2 in _edits(c, letters)) {
          if (_rank.containsKey(c2)) consider(c2, 2);
        }
      }
    }
    // Deux mots collés : « quelquechose » → « quelque chose », proposé
    // seulement si les deux moitiés existent.
    for (var i = 2; i < min(lower.length - 1, 24); i++) {
      final a = _rank[lower.substring(0, i)];
      final b = _rank[lower.substring(i)];
      if (a != null && b != null) {
        found.putIfAbsent(
          '${lower.substring(0, i)} ${lower.substring(i)}',
          () => log(max(a, b) + 2) + 3.5,
        );
      }
    }
    final sorted = found.keys.toList()
      ..sort((a, b) => found[a]!.compareTo(found[b]!));
    final capitalized =
        original.isNotEmpty && original[0] != original[0].toLowerCase();
    final result = <String>[];
    for (final s in sorted) {
      final out = capitalized && s.isNotEmpty
          ? s[0].toUpperCase() + s.substring(1)
          : s;
      if (out != original && !result.contains(out)) result.add(out);
      if (result.length >= limit) break;
    }
    return result;
  }

  static Iterable<String> _edits(String w, String letters) sync* {
    for (var i = 0; i <= w.length; i++) {
      final a = w.substring(0, i);
      final b = w.substring(i);
      if (b.isNotEmpty) yield a + b.substring(1);
      if (b.length > 1) yield a + b[1] + b[0] + b.substring(2);
      for (var k = 0; k < letters.length; k++) {
        final ch = letters[k];
        if (b.isNotEmpty) yield a + ch + b.substring(1);
        yield a + ch + b;
      }
    }
  }

  static const _accents = {
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'ç': 'c',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'î': 'i',
    'ï': 'i',
    'ô': 'o',
    'ö': 'o',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ÿ': 'y',
  };

  static String _stripAccents(String w) => w
      .split('')
      .map((c) => _accents[c] ?? c)
      .join()
      .replaceAll('œ', 'oe')
      .replaceAll('æ', 'ae');
}
