import 'package:flutter/material.dart';

import '../../core/app_scope.dart';

/// Mots ajoutés par l'utilisateur : acceptés par le correcteur et reconnus
/// en priorité par la transcription.
class PersonalDictionaryScreen extends StatefulWidget {
  const PersonalDictionaryScreen({super.key});

  @override
  State<PersonalDictionaryScreen> createState() =>
      _PersonalDictionaryScreenState();
}

class _PersonalDictionaryScreenState extends State<PersonalDictionaryScreen> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _add() {
    final settings = AppScope.of(context).settings;
    for (final word in _input.text.split(RegExp(r'[,;\n]'))) {
      settings.addPersonalWord(word);
    }
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Dictionnaire personnel')),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Text(
              'Noms propres, mots de métier, sigles : le correcteur ne les '
              'souligne plus, et la transcription les reconnaît mieux.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('personal-word-input'),
                    controller: _input,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _add(),
                    decoration: const InputDecoration(
                      labelText: 'Ajouter un mot',
                      hintText: 'Chabane, Murmure…',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Ajouter',
                  onPressed: _add,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (settings.personalWords.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Aucun mot pour l’instant. Vous pouvez aussi en ajouter '
                  'depuis un texte transcrit, en touchant un mot souligné.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final word in settings.personalWords)
                    InputChip(
                      label: Text(word),
                      onDeleted: () => settings.removePersonalWord(word),
                      deleteButtonTooltipMessage: 'Retirer « $word »',
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
