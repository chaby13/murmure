import 'package:flutter/material.dart';

import '../../domain/text/spell_checker.dart';

/// Champ de texte qui souligne les mots inconnus du correcteur et peut
/// surligner un passage (recherche, phrase trop longue).
class SpellCheckController extends TextEditingController {
  SpellCheckController({super.text});

  SpellChecker? _checker;
  final Set<String> _ignored = {};
  String? _checkedText;
  List<WordSpan> _misspelled = const [];
  TextRange? _highlight;

  SpellChecker? get checker => _checker;

  set checker(SpellChecker? value) {
    _checker = value;
    _checkedText = null;
    notifyListeners();
  }

  /// Passage surligné (résultat de recherche…), ou null.
  TextRange? get highlight => _highlight;

  set highlight(TextRange? value) {
    _highlight = value;
    notifyListeners();
  }

  /// Ignore [word] jusqu'à la fermeture de l'écran.
  void ignore(String word) {
    _ignored.add(word.toLowerCase());
    _checkedText = null;
    notifyListeners();
  }

  /// Le correcteur a changé (mot ajouté au dictionnaire personnel).
  void refresh() {
    _checkedText = null;
    notifyListeners();
  }

  /// Mots à vérifier, dans l'ordre du texte.
  List<WordSpan> get misspelled {
    final checker = _checker;
    if (checker == null) return const [];
    if (_checkedText != text) {
      _checkedText = text;
      _misspelled = [
        for (final w in checker.misspelled(text))
          if (!_ignored.contains(w.text.toLowerCase())) w,
      ];
    }
    return _misspelled;
  }

  /// Mot à vérifier sous le curseur, s'il y en a un.
  WordSpan? get wordAtCursor {
    final s = selection;
    if (!s.isValid) return null;
    for (final w in misspelled) {
      if (s.start >= w.start && s.end <= w.end) return w;
    }
    return null;
  }

  /// Remplace [word] par [replacement] et place le curseur après.
  void replaceWord(WordSpan word, String replacement) {
    final updated = text.replaceRange(word.start, word.end, replacement);
    value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(
        offset: word.start + replacement.length,
      ),
    );
  }

  /// Sélectionne le prochain mot à vérifier après le curseur (boucle au
  /// début). Renvoie false s'il n'y en a aucun.
  bool selectNextMisspelled() {
    final words = misspelled;
    if (words.isEmpty) return false;
    final from = selection.isValid ? selection.end : 0;
    final next = words.firstWhere(
      (w) => w.start >= from && !(selection.start == w.start),
      orElse: () => words.first,
    );
    selection = TextSelection(baseOffset: next.start, extentOffset: next.end);
    return true;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // Pendant une saisie au clavier du téléphone, affichage standard.
    if (withComposing && value.isComposingRangeValid) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }
    final scheme = Theme.of(context).colorScheme;
    final marks = <(int, int, TextStyle)>[
      for (final w in misspelled)
        (
          w.start,
          w.end,
          TextStyle(
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.wavy,
            decorationColor: scheme.error,
            decorationThickness: 1.6,
          ),
        ),
    ];
    final h = _highlight;
    final children = <InlineSpan>[];
    var pos = 0;
    // Découpe le texte aux bords des mots soulignés et du surlignage.
    final cuts = <int>{0, text.length};
    for (final m in marks) {
      cuts
        ..add(m.$1)
        ..add(m.$2);
    }
    if (h != null && h.isValid && h.end <= text.length) {
      cuts
        ..add(h.start)
        ..add(h.end);
    }
    final sorted = cuts.toList()..sort();
    var markIndex = 0;
    for (final end in sorted.skip(1)) {
      if (end <= pos) continue;
      TextStyle? s;
      while (markIndex < marks.length && marks[markIndex].$2 <= pos) {
        markIndex++;
      }
      if (markIndex < marks.length &&
          marks[markIndex].$1 <= pos &&
          marks[markIndex].$2 >= end) {
        s = marks[markIndex].$3;
      }
      if (h != null && h.isValid && h.start <= pos && h.end >= end) {
        s = (s ?? const TextStyle()).copyWith(
          backgroundColor: scheme.tertiaryContainer,
        );
      }
      children.add(TextSpan(text: text.substring(pos, end), style: s));
      pos = end;
    }
    return TextSpan(style: style, children: children);
  }
}
