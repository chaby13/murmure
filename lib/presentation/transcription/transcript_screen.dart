import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_scope.dart';
import '../../core/router/app_router.dart';
import '../../domain/models/app_language.dart';
import '../../domain/services/library_repository.dart';
import '../../domain/text/spell_checker.dart';
import '../../domain/text/text_analysis.dart';
import '../../domain/text/typography.dart';
import '../widgets/empty_state.dart';
import 'spell_check_controller.dart';

/// Texte d'une transcription : correction (orthographe, typographie,
/// rechercher et remplacer), analyse, copie et export en TXT.
class TranscriptScreen extends StatefulWidget {
  const TranscriptScreen({super.key, required this.itemId});

  final String itemId;

  @override
  State<TranscriptScreen> createState() => _TranscriptScreenState();
}

class _TranscriptScreenState extends State<TranscriptScreen> {
  final _text = SpellCheckController();
  final _focus = FocusNode();
  String _saved = '';
  bool _loading = true;
  String? _error;

  AppLanguage _language = AppLanguage.fr;
  bool _spellLoading = false;
  String? _spellError;

  bool _findOpen = false;
  final _find = TextEditingController();
  final _replace = TextEditingController();
  int _match = 0;

  String? _suggestionsFor;
  List<String> _suggestions = const [];

  late final _deps = AppScope.of(context);
  LibraryRepository get _library => _deps.library;

  bool get _dirty => _text.text != _saved;

  @override
  void initState() {
    super.initState();
    _text.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final text = await _library.readText(widget.itemId);
      if (!mounted) return;
      _saved = text;
      _text.text = text;
      _language = TextAnalysis.languageOf(text);
      setState(() => _loading = false);
      _loadChecker();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadChecker() async {
    final language = _language;
    setState(() {
      _spellLoading = true;
      _spellError = null;
    });
    try {
      final checker = await _deps.spelling.of(language);
      if (!mounted || language != _language) return;
      checker.personal = _personalSet();
      _text.checker = checker;
    } catch (_) {
      if (mounted) _spellError = 'Correcteur indisponible.';
    } finally {
      if (mounted) setState(() => _spellLoading = false);
    }
  }

  Set<String> _personalSet() => {
    for (final w in _deps.settings.personalWords) w.toLowerCase(),
  };

  void _onTextChanged() {
    final word = _text.wordAtCursor;
    if (word?.text != _suggestionsFor) {
      _suggestionsFor = word?.text;
      _suggestions = word == null
          ? const []
          : _text.checker?.suggest(word.text) ?? const [];
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _text.removeListener(_onTextChanged);
    _text.dispose();
    _focus.dispose();
    _find.dispose();
    _replace.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_dirty) return;
    final text = _text.text;
    await _library.saveText(widget.itemId, text);
    if (!mounted) return;
    setState(() => _saved = text);
    _show('Corrections enregistrées.');
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _text.text));
    _show('Texte copié.');
  }

  Future<void> _export(String title) async {
    final picker = _deps.picker;
    final name = title.toLowerCase().endsWith('.txt') ? title : '$title.txt';
    try {
      final saved = await picker.exportText(name, _text.text);
      if (saved) _show('Fichier TXT enregistré.');
    } catch (_) {
      _show('L’export a échoué.');
    }
  }

  void _show(String text, {SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), action: action));
  }

  void _setLanguage(AppLanguage language) {
    if (language == _language) return;
    setState(() => _language = language);
    _text.checker = null;
    _suggestionsFor = null;
    _loadChecker();
  }

  // ----- Orthographe -----

  void _applySuggestion(WordSpan word, String replacement) {
    _text.replaceWord(word, replacement);
    _focus.requestFocus();
  }

  void _addToDictionary(WordSpan word) {
    _deps.settings.addPersonalWord(word.text);
    _text.checker?.personal = _personalSet();
    _text.refresh();
    _suggestionsFor = null;
    _show('« ${word.text} » ajouté au dictionnaire personnel.');
  }

  void _nextMistake() {
    if (!_text.selectNextMisspelled()) {
      _show('Aucun mot à vérifier.');
      return;
    }
    _focus.requestFocus();
  }

  // ----- Typographie -----

  void _fixTypography() {
    final before = _text.value;
    final fixed = fixTypography(_text.text, _language);
    if (fixed == _text.text) {
      _show('La typographie est déjà correcte.');
      return;
    }
    _text.value = TextEditingValue(
      text: fixed,
      selection: TextSelection.collapsed(offset: fixed.length),
    );
    _show(
      'Typographie corrigée.',
      action: SnackBarAction(
        label: 'Annuler',
        onPressed: () => _text.value = before,
      ),
    );
  }

  // ----- Rechercher et remplacer -----

  List<TextRange> get _matches {
    final needle = _find.text;
    if (needle.isEmpty) return const [];
    final hay = _text.text.toLowerCase();
    final n = needle.toLowerCase();
    final out = <TextRange>[];
    var i = hay.indexOf(n);
    while (i >= 0) {
      out.add(TextRange(start: i, end: i + n.length));
      i = hay.indexOf(n, i + n.length);
    }
    return out;
  }

  void _showMatch(int index) {
    final matches = _matches;
    if (matches.isEmpty) {
      _text.highlight = null;
      setState(() => _match = 0);
      return;
    }
    _match = index % matches.length;
    final m = matches[_match];
    _text.highlight = m;
    _text.selection = TextSelection(baseOffset: m.start, extentOffset: m.end);
    setState(() {});
  }

  void _replaceCurrent() {
    final matches = _matches;
    if (matches.isEmpty) return;
    final m = matches[_match % matches.length];
    _text.value = TextEditingValue(
      text: _text.text.replaceRange(m.start, m.end, _replace.text),
      selection: TextSelection.collapsed(
        offset: m.start + _replace.text.length,
      ),
    );
    _showMatch(_match);
  }

  void _replaceAll() {
    final count = _matches.length;
    if (count == 0) return;
    _text.value = TextEditingValue(
      text: _text.text.replaceAll(
        RegExp(RegExp.escape(_find.text), caseSensitive: false),
        _replace.text,
      ),
    );
    _text.highlight = null;
    setState(() => _match = 0);
    _show('$count remplacement(s).');
  }

  void _toggleFind() {
    setState(() => _findOpen = !_findOpen);
    if (!_findOpen) _text.highlight = null;
  }

  // ----- Analyse -----

  void _showAnalysis() {
    final a = TextAnalysis.of(_text.text, _language);
    final mistakes = _text.misspelled.length;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (context, controller) => _AnalysisSheet(
          analysis: a,
          mistakes: _text.checker == null ? null : mistakes,
          controller: controller,
          onSelect: (start, end) {
            Navigator.pop(context);
            _text.highlight = TextRange(start: start, end: end);
            _text.selection = TextSelection(
              baseOffset: start,
              extentOffset: end,
            );
            _focus.requestFocus();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = _deps.library.byId(widget.itemId);
    final title = item?.title ?? 'Transcription';
    final ready = !_loading && _error == null && item != null;
    final Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (!ready) {
      body = EmptyState(
        icon: Icons.find_in_page_outlined,
        title: 'Transcription introuvable',
        message: _error ?? 'Ce texte n’existe plus dans la bibliothèque.',
      );
    } else {
      final word = _text.wordAtCursor;
      body = Column(
        children: [
          if (_findOpen) _findBar(context),
          _spellBar(context),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                key: const Key('transcript-text'),
                controller: _text,
                focusNode: _focus,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(height: 1.5),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Texte de la transcription',
                ),
              ),
            ),
          ),
          if (word != null) _suggestionBar(context, word),
        ],
      );
    }

    final scaffold = Scaffold(
      appBar: AppBar(
        title: Text(title, overflow: TextOverflow.ellipsis),
        actions: [
          if (ready) ...[
            IconButton(
              tooltip: 'Enregistrer les corrections',
              onPressed: _dirty ? _save : null,
              icon: const Icon(Icons.save_outlined),
            ),
            IconButton(
              tooltip: 'Rechercher et remplacer',
              isSelected: _findOpen,
              onPressed: _toggleFind,
              icon: const Icon(Icons.find_replace),
            ),
            IconButton(
              tooltip: 'Analyse du texte',
              onPressed: _showAnalysis,
              icon: const Icon(Icons.insights_outlined),
            ),
            IconButton(
              tooltip: 'Exporter en TXT',
              onPressed: () => _export(title),
              icon: const Icon(Icons.file_download_outlined),
            ),
            PopupMenuButton<String>(
              tooltip: 'Plus d’actions',
              onSelected: (value) => switch (value) {
                'typo' => _fixTypography(),
                'copy' => _copy(),
                'dico' => context.push(AppRoutes.dictionary),
                _ => null,
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'typo',
                  child: ListTile(
                    leading: Icon(Icons.format_quote),
                    title: Text('Corriger la typographie'),
                  ),
                ),
                PopupMenuItem(
                  value: 'copy',
                  child: ListTile(
                    leading: Icon(Icons.copy),
                    title: Text('Copier le texte'),
                  ),
                ),
                PopupMenuItem(
                  value: 'dico',
                  child: ListTile(
                    leading: Icon(Icons.spellcheck),
                    title: Text('Dictionnaire personnel'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: body,
    );

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        // Les corrections ne sont jamais perdues en quittant l'écran.
        if (didPop && _dirty) _library.saveText(widget.itemId, _text.text);
      },
      // Raccourcis clavier (Windows) : Ctrl+S, Ctrl+F, F7 faute suivante.
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyS, control: true): _save,
          const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
            if (!_findOpen) _toggleFind();
          },
          const SingleActivator(LogicalKeyboardKey.f7): _nextMistake,
        },
        child: scaffold,
      ),
    );
  }

  Widget _spellBar(BuildContext context) {
    final theme = Theme.of(context);
    final count = _text.misspelled.length;
    final String status;
    if (_spellLoading) {
      status = 'Préparation du correcteur…';
    } else if (_spellError != null) {
      status = _spellError!;
    } else if (count == 0) {
      status = 'Aucun mot à vérifier';
    } else {
      status = count == 1 ? '1 mot à vérifier' : '$count mots à vérifier';
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
      child: Row(
        children: [
          SegmentedButton<AppLanguage>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: const [
              ButtonSegment(value: AppLanguage.fr, label: Text('FR')),
              ButtonSegment(value: AppLanguage.en, label: Text('EN')),
            ],
            selected: {_language},
            onSelectionChanged: (s) => _setLanguage(s.first),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              status,
              key: const Key('spell-status'),
              style: theme.textTheme.bodySmall,
            ),
          ),
          TextButton.icon(
            onPressed: count == 0 ? null : _nextMistake,
            icon: const Icon(Icons.skip_next),
            label: const Text('Suivant'),
          ),
        ],
      ),
    );
  }

  Widget _suggestionBar(BuildContext context, WordSpan word) {
    final theme = Theme.of(context);
    return Material(
      key: const Key('suggestion-bar'),
      color: theme.colorScheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Text('« ${word.text} »', style: theme.textTheme.labelLarge),
                    const SizedBox(width: 8),
                    if (_suggestions.isEmpty)
                      const Text('Aucune suggestion')
                    else
                      for (final s in _suggestions)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text(s),
                            onPressed: () => _applySuggestion(word, s),
                          ),
                        ),
                  ],
                ),
              ),
              Wrap(
                children: [
                  TextButton.icon(
                    onPressed: () => _addToDictionary(word),
                    icon: const Icon(Icons.library_add_outlined),
                    label: const Text('Ajouter au dictionnaire'),
                  ),
                  TextButton(
                    onPressed: () {
                      _text.ignore(word.text);
                      _suggestionsFor = null;
                    },
                    child: const Text('Ignorer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _findBar(BuildContext context) {
    final count = _matches.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('find-input'),
                  controller: _find,
                  autofocus: true,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: 'Rechercher',
                    suffixText: _find.text.isEmpty
                        ? null
                        : count == 0
                        ? '0'
                        : '${_match % count + 1}/$count',
                  ),
                  onChanged: (_) => _showMatch(0),
                  onSubmitted: (_) => _showMatch(_match + 1),
                ),
              ),
              IconButton(
                tooltip: 'Précédent',
                onPressed: count == 0 ? null : () => _showMatch(_match - 1),
                icon: const Icon(Icons.keyboard_arrow_up),
              ),
              IconButton(
                tooltip: 'Suivant',
                onPressed: count == 0 ? null : () => _showMatch(_match + 1),
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('replace-input'),
                  controller: _replace,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Remplacer par',
                  ),
                ),
              ),
              TextButton(
                onPressed: count == 0 ? null : _replaceCurrent,
                child: const Text('Remplacer'),
              ),
              TextButton(
                onPressed: count == 0 ? null : _replaceAll,
                child: const Text('Tout'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnalysisSheet extends StatelessWidget {
  const _AnalysisSheet({
    required this.analysis,
    required this.mistakes,
    required this.controller,
    required this.onSelect,
  });

  final TextAnalysis analysis;
  final int? mistakes;
  final ScrollController controller;
  final void Function(int start, int end) onSelect;

  static String _duration(Duration d) {
    if (d.inMinutes < 1) return '${d.inSeconds} s';
    final s = d.inSeconds % 60;
    return s == 0 ? '${d.inMinutes} min' : '${d.inMinutes} min $s s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = analysis;
    final stats = [
      ('Mots', '${a.words}'),
      ('Mots différents', '${a.distinctWords}'),
      ('Phrases', '${a.sentences}'),
      ('Paragraphes', '${a.paragraphs}'),
      ('Signes (sans espaces)', '${a.characters}'),
      ('Mots par phrase', a.averageSentenceWords.toStringAsFixed(1)),
      ('Temps de lecture', _duration(a.readingTime)),
      ('Temps d’écoute', _duration(a.listeningTime)),
      if (mistakes != null) ('Mots à vérifier', '$mistakes'),
    ];
    return ListView(
      key: const Key('analysis-sheet'),
      controller: controller,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        Text('Analyse du texte', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        for (final (label, value) in stats)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: Text(label)),
                Text(value, style: theme.textTheme.titleSmall),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Text(
          a.longSentences.isEmpty
              ? 'Aucune phrase trop longue.'
              : 'Phrases de plus de ${TextAnalysis.longSentenceWords} mots '
                    '(touchez pour les retrouver)',
          style: theme.textTheme.titleSmall,
        ),
        for (final s in a.longSentences)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.short_text),
            title: Text('${s.words} mots, position ${s.start + 1}'),
            onTap: () => onSelect(s.start, s.end),
          ),
        if (a.frequentWords.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Mots les plus employés', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in a.frequentWords)
                Chip(label: Text('${e.key} · ${e.value}')),
            ],
          ),
        ],
      ],
    );
  }
}
