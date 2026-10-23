import '../models/app_language.dart';
import 'reading_text.dart';
import 'spell_checker.dart';

/// Une phrase jugée trop longue, avec sa position dans le texte.
class LongSentence {
  const LongSentence(this.start, this.end, this.words);

  final int start;
  final int end;
  final int words;
}

/// Chiffres clés d'un texte : volume, lisibilité, mots dominants.
class TextAnalysis {
  TextAnalysis._({
    required this.words,
    required this.characters,
    required this.sentences,
    required this.paragraphs,
    required this.longSentences,
    required this.frequentWords,
    required this.distinctWords,
  });

  /// Au-delà, une phrase est difficile à suivre à l'écoute.
  static const longSentenceWords = 30;

  /// Lecture silencieuse et écoute, en mots par minute.
  static const readingSpeed = 230;
  static const listeningSpeed = 150;

  final int words;
  final int characters;
  final int sentences;
  final int paragraphs;
  final int distinctWords;
  final List<LongSentence> longSentences;

  /// Mots les plus employés (hors mots outils), avec leur nombre.
  final List<MapEntry<String, int>> frequentWords;

  Duration get readingTime =>
      Duration(seconds: (words * 60 / readingSpeed).ceil());
  Duration get listeningTime =>
      Duration(seconds: (words * 60 / listeningSpeed).ceil());
  double get averageSentenceWords => sentences == 0 ? 0 : words / sentences;

  factory TextAnalysis.of(String text, AppLanguage language) {
    final all = wordsOf(text).toList();
    final counts = <String, int>{};
    for (final w in all) {
      final key = w.text.toLowerCase().replaceAll('’', "'");
      final bare = key.contains("'")
          ? key.substring(key.indexOf("'") + 1)
          : key;
      if (bare.length < 3 || _stopWords[language]!.contains(bare)) continue;
      counts[bare] = (counts[bare] ?? 0) + 1;
    }
    final frequent = counts.entries.where((e) => e.value > 1).toList()
      ..sort(
        (a, b) => b.value != a.value
            ? b.value.compareTo(a.value)
            : a.key.compareTo(b.key),
      );

    final long = <LongSentence>[];
    var sentenceCount = 0;
    for (final m in RegExp(r'[^.!?…\n]+[.!?…]*').allMatches(text)) {
      final n = wordsOf(m[0]!).length;
      if (n == 0) continue;
      sentenceCount++;
      if (n > longSentenceWords) long.add(LongSentence(m.start, m.end, n));
    }
    return TextAnalysis._(
      words: all.length,
      characters: text.replaceAll(RegExp(r'\s'), '').length,
      sentences: sentenceCount,
      paragraphs: text
          .split(RegExp(r'\n\s*\n|\n'))
          .where((p) => p.trim().isNotEmpty)
          .length,
      distinctWords: {for (final w in all) w.text.toLowerCase()}.length,
      longSentences: long,
      frequentWords: frequent.take(10).toList(),
    );
  }

  /// Langue probable du texte, français par défaut.
  static AppLanguage languageOf(String text) =>
      detectLanguage(text) ?? AppLanguage.fr;
}

const _stopWords = {
  AppLanguage.fr: {
    'les',
    'des',
    'une',
    'est',
    'que',
    'qui',
    'dans',
    'pour',
    'pas',
    'sur',
    'avec',
    'nous',
    'vous',
    'ils',
    'elle',
    'elles',
    'mais',
    'ou',
    'donc',
    'car',
    'ses',
    'son',
    'sa',
    'leur',
    'leurs',
    'ces',
    'cette',
    'cet',
    'aux',
    'par',
    'plus',
    'tout',
    'tous',
    'toute',
    'toutes',
    'été',
    'être',
    'avoir',
    'fait',
    'faire',
    'comme',
    'aussi',
    'bien',
    'très',
    'sont',
    'ont',
    'était',
    'mon',
    'ton',
    'mes',
    'tes',
    'nos',
    'vos',
    'notre',
    'votre',
    'moi',
    'toi',
    'lui',
    'eux',
    'quand',
    'alors',
    'puis',
    'ainsi',
    'encore',
    'même',
    'peu',
    'non',
    'oui',
    'ici',
    'là',
    'cela',
    'ceci',
    'ça',
    'rien',
    'dont',
    'où',
    'entre',
    'sans',
    'sous',
    'vers',
    'chez',
    'après',
    'avant',
    'déjà',
    'jamais',
    'quoi',
    'peut',
    'faut',
    'suis',
    'es',
    'sommes',
    'êtes',
    'ai',
    'as',
    'avons',
    'avez',
    'qu',
    'il',
    'je',
    'tu',
    'on',
    'le',
    'la',
    'de',
    'du',
    'et',
  },
  AppLanguage.en: {
    'the',
    'and',
    'that',
    'this',
    'with',
    'for',
    'are',
    'was',
    'were',
    'you',
    'your',
    'they',
    'them',
    'their',
    'have',
    'has',
    'had',
    'not',
    'but',
    'from',
    'what',
    'which',
    'who',
    'when',
    'where',
    'there',
    'here',
    'been',
    'being',
    'will',
    'would',
    'can',
    'could',
    'should',
    'about',
    'into',
    'than',
    'then',
    'also',
    'just',
    'very',
    'more',
    'some',
    'any',
    'all',
    'our',
    'its',
    'his',
    'her',
    'she',
    'him',
    'how',
    'why',
    'one',
    'out',
    'now',
    'only',
    'over',
    'such',
    'like',
    'these',
    'those',
    'because',
    'did',
    'does',
    'don\'t',
  },
};
