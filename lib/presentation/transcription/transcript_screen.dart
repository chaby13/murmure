import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_scope.dart';
import '../../domain/services/library_repository.dart';
import '../widgets/empty_state.dart';

/// Texte d'une transcription : correction, copie et export en TXT.
class TranscriptScreen extends StatefulWidget {
  const TranscriptScreen({super.key, required this.itemId});

  final String itemId;

  @override
  State<TranscriptScreen> createState() => _TranscriptScreenState();
}

class _TranscriptScreenState extends State<TranscriptScreen> {
  final _text = TextEditingController();
  String _saved = '';
  bool _loading = true;
  String? _error;

  late final LibraryRepository _library = AppScope.of(context).library;

  bool get _dirty => _text.text != _saved;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final text = await _library.readText(widget.itemId);
      if (!mounted) return;
      _saved = text;
      _text.text = text;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _text.dispose();
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
    final picker = AppScope.of(context).picker;
    final name = title.toLowerCase().endsWith('.txt') ? title : '$title.txt';
    try {
      final saved = await picker.exportText(name, _text.text);
      if (saved) _show('Fichier TXT enregistré.');
    } catch (_) {
      _show('L’export a échoué.');
    }
  }

  void _show(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final item = AppScope.of(context).library.byId(widget.itemId);
    final title = item?.title ?? 'Transcription';
    final Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null || item == null) {
      body = EmptyState(
        icon: Icons.find_in_page_outlined,
        title: 'Transcription introuvable',
        message: _error ?? 'Ce texte n’existe plus dans la bibliothèque.',
      );
    } else {
      body = Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: TextField(
          key: const Key('transcript-text'),
          controller: _text,
          onChanged: (_) => setState(() {}),
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Texte de la transcription',
          ),
        ),
      );
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        // Les corrections ne sont jamais perdues en quittant l'écran.
        if (didPop && _dirty) _library.saveText(widget.itemId, _text.text);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title, overflow: TextOverflow.ellipsis),
          actions: [
            if (!_loading && _error == null && item != null) ...[
              IconButton(
                tooltip: 'Enregistrer les corrections',
                onPressed: _dirty ? _save : null,
                icon: const Icon(Icons.save_outlined),
              ),
              IconButton(
                tooltip: 'Copier le texte',
                onPressed: _copy,
                icon: const Icon(Icons.copy),
              ),
              IconButton(
                tooltip: 'Exporter en TXT',
                onPressed: () => _export(title),
                icon: const Icon(Icons.file_download_outlined),
              ),
            ],
          ],
        ),
        body: body,
      ),
    );
  }
}
