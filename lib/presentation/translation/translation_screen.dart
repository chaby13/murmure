import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_scope.dart';
import '../../domain/models/app_language.dart';
import '../../domain/services/local_engines.dart';

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({super.key});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  final _input = TextEditingController();
  AppLanguage _from = AppLanguage.en;
  String? _translation;
  String? _error;
  bool _busy = false;

  AppLanguage get _to => _from.other;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _swap() => setState(() {
    _from = _from.other;
    _translation = null;
    _error = null;
  });

  Future<void> _translate() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    final engine = AppScope.of(context).engines.translation;
    setState(() {
      _busy = true;
      _error = null;
      _translation = null;
    });
    try {
      final result = await engine.translate(text, from: _from, to: _to);
      if (mounted) setState(() => _translation = result);
    } on EngineNotIntegratedException catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Traduction')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Center(
                  child: Text(_from.label, key: const Key('from-language')),
                ),
              ),
              IconButton(
                tooltip: 'Inverser les langues',
                icon: const Icon(Icons.swap_horiz),
                onPressed: _swap,
              ),
              Expanded(
                child: Center(
                  child: Text(_to.label, key: const Key('to-language')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _input,
            minLines: 4,
            maxLines: 10,
            decoration: InputDecoration(
              labelText: 'Texte original (${_from.label.toLowerCase()})',
              alignLabelWithHint: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                tooltip: 'Copier l’original',
                icon: const Icon(Icons.copy_outlined),
                onPressed: _input.text.isEmpty
                    ? null
                    : () => Clipboard.setData(ClipboardData(text: _input.text)),
              ),
              const IconButton(
                tooltip: 'Écouter l’original (TTS-01 non intégré)',
                icon: Icon(Icons.volume_up_outlined),
                onPressed: null,
              ),
              const Spacer(),
              FilledButton.icon(
                icon: const Icon(Icons.translate),
                label: const Text('Traduire'),
                onPressed: _busy || _input.text.trim().isEmpty
                    ? null
                    : _translate,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            key: const Key('translation-output'),
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(minHeight: 120),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Traduction (${_to.label.toLowerCase()})',
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: 8),
                if (_busy)
                  const LinearProgressIndicator()
                else if (_translation != null)
                  SelectableText(
                    _translation!,
                    style: theme.textTheme.bodyLarge,
                  )
                else if (_error != null)
                  Text(
                    '$_error\nAucune traduction n’a été produite.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  Text(
                    'La traduction locale apparaîtra ici.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
