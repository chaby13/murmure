import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../domain/models/app_language.dart';
import '../widgets/empty_state.dart';
import '../widgets/not_integrated.dart';

enum _TranscriptionTab { record, file, results }

/// Langue de transcription. « Auto » dépendra des capacités du moteur retenu.
enum _AsrLanguage { fr, en, auto }

class TranscriptionScreen extends StatefulWidget {
  const TranscriptionScreen({super.key});

  @override
  State<TranscriptionScreen> createState() => _TranscriptionScreenState();
}

class _TranscriptionScreenState extends State<TranscriptionScreen> {
  _TranscriptionTab _tab = _TranscriptionTab.record;
  _AsrLanguage _language = _AsrLanguage.fr;

  @override
  Widget build(BuildContext context) {
    final asr = AppScope.of(context).engines.asr;
    return Scaffold(
      appBar: AppBar(title: const Text('Transcription')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          SegmentedButton<_TranscriptionTab>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: _TranscriptionTab.record,
                label: Text('Enregistrer'),
              ),
              ButtonSegment(
                value: _TranscriptionTab.file,
                label: Text('Fichier audio'),
              ),
              ButtonSegment(
                value: _TranscriptionTab.results,
                label: Text('Résultats'),
              ),
            ],
            selected: {_tab},
            onSelectionChanged: (value) => setState(() => _tab = value.first),
          ),
          const SizedBox(height: 24),
          ...switch (_tab) {
            _TranscriptionTab.record => _recordTab(context, asr.ticket),
            _TranscriptionTab.file => [
              EmptyState(
                icon: Icons.audio_file_outlined,
                title: 'Importer un fichier audio',
                message:
                    'Formats prévus : WAV, M4A, MP3, selon les '
                    'décodeurs retenus. L’import n’est pas encore disponible.',
                action: OutlinedButton.icon(
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Choisir un fichier'),
                  onPressed: () =>
                      showNotIntegrated(context, 'Import audio', 'ASR-02'),
                ),
              ),
            ],
            _TranscriptionTab.results => const [
              EmptyState(
                icon: Icons.notes_outlined,
                title: 'Aucune transcription',
                message:
                    'Vos transcriptions apparaîtront ici, modifiables '
                    'et exportables en TXT.',
              ),
            ],
          },
        ],
      ),
    );
  }

  List<Widget> _recordTab(BuildContext context, String ticket) {
    final theme = Theme.of(context);
    return [
      Center(
        child: Semantics(
          button: true,
          label: 'Démarrer l’enregistrement',
          excludeSemantics: true,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => showNotIntegrated(
              context,
              'Enregistrement et transcription',
              ticket,
            ),
            child: CircleAvatar(
              radius: 64,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: CircleAvatar(
                radius: 46,
                backgroundColor: theme.colorScheme.primary,
                child: Icon(
                  Icons.mic,
                  size: 40,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Text(
        '00:00:00',
        textAlign: TextAlign.center,
        style: theme.textTheme.headlineSmall,
      ),
      const SizedBox(height: 4),
      Text(
        'Moteur de transcription local non intégré : aucun son n’est enregistré.',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 24),
      Text('Langue parlée', style: theme.textTheme.titleSmall),
      const SizedBox(height: 8),
      SegmentedButton<_AsrLanguage>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: _AsrLanguage.fr,
            label: Text(AppLanguage.fr.label),
          ),
          ButtonSegment(
            value: _AsrLanguage.en,
            label: Text(AppLanguage.en.label),
          ),
          const ButtonSegment(value: _AsrLanguage.auto, label: Text('Auto')),
        ],
        selected: {_language},
        onSelectionChanged: (value) => setState(() => _language = value.first),
      ),
    ];
  }
}
