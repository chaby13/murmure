import '../models/app_language.dart';

/// Découpe le texte d'une page PDF en phrases à lire une par une.
/// Recolle les mots coupés en fin de ligne et ignore les lignes vides.
List<String> splitSentences(String text) {
  final cleaned = text
      .replaceAll('\r', '')
      .replaceAllMapped(
        RegExp(r'(\p{L})-\n(\p{L})', unicode: true),
        (m) => '${m[1]}${m[2]}',
      )
      .replaceAll(RegExp(r'\s*\n\s*\n\s*'), '\n\n')
      .replaceAll(RegExp(r'(?<!\n)\n(?!\n)'), ' ')
      .replaceAll(RegExp(r'[ \t]+'), ' ');

  final sentences = <String>[];
  for (final block in cleaned.split('\n\n')) {
    final parts = block.split(RegExp(r'(?<=[.!?…])\s+(?=\S)'));
    for (final part in parts) {
      final sentence = part.trim();
      if (sentence.isNotEmpty &&
          RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(sentence)) {
        sentences.add(sentence);
      }
    }
  }
  return sentences;
}

const _frenchWords = {
  'le',
  'la',
  'les',
  'des',
  'du',
  'de',
  'un',
  'une',
  'et',
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
  'il',
  'elle',
};
const _englishWords = {
  'the',
  'and',
  'is',
  'are',
  'of',
  'to',
  'in',
  'that',
  'it',
  'with',
  'for',
  'you',
  'we',
  'this',
  'on',
  'be',
  'was',
  'not',
  'have',
  'they',
};

/// Devine si un texte est en français ou en anglais à partir de mots très
/// courants. Renvoie null si le texte est trop court pour trancher.
AppLanguage? detectLanguage(String text) {
  final words = RegExp(
    r"[\p{L}']+",
    unicode: true,
  ).allMatches(text.toLowerCase()).map((m) => m.group(0)!).toList();
  var fr = 0, en = 0;
  for (final word in words) {
    if (_frenchWords.contains(word)) fr++;
    if (_englishWords.contains(word)) en++;
  }
  fr += RegExp('[éèêàçùœ]').allMatches(text.toLowerCase()).length;
  if (fr + en < 3) return null;
  return fr >= en ? AppLanguage.fr : AppLanguage.en;
}
