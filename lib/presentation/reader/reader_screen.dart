import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/theme/murmure_colors.dart';
import '../../domain/models/library_item.dart';
import '../widgets/empty_state.dart';
import '../widgets/library_item_icon.dart';
import '../widgets/not_integrated.dart';
import '../widgets/sample_data_banner.dart';

/// Texte de démonstration affiché à la place d'une extraction PDF réelle.
const _sampleChapter = [
  'Learning a new language requires patience, practice and curiosity.',
  'Every small step brings you closer to understanding the world around you.',
  'Knowledge grows when we take the time to reflect on what we read. '
      'The more we explore, the more we discover new perspectives.',
];

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.itemId});

  final String itemId;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  @override
  void initState() {
    super.initState();
    // Mémorise l'ouverture pour « Reprendre ma lecture ».
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).library.markOpened(widget.itemId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final deps = AppScope.of(context);
    final item = deps.library.byId(widget.itemId);
    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.find_in_page_outlined,
          title: 'Document introuvable',
          message: 'Ce document n’existe plus dans la bibliothèque.',
        ),
      );
    }

    return ListenableBuilder(
      listenable: deps.settings,
      builder: (context, _) {
        final mode = deps.settings.readerMode;
        final theme = Theme.of(context);
        return Scaffold(
          backgroundColor: mode.background,
          appBar: AppBar(
            backgroundColor: mode.background,
            foregroundColor: mode.text,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: mode.text,
                  ),
                ),
                if (item.pageCount != null)
                  Text(
                    'Page ${item.currentPage ?? 1} sur ${item.pageCount}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: mode.text,
                    ),
                  ),
              ],
            ),
            actions: [
              PopupMenuButton<ReaderMode>(
                tooltip: 'Mode de lecture',
                icon: const Icon(Icons.contrast),
                initialValue: mode,
                onSelected: (value) => deps.settings.readerMode = value,
                itemBuilder: (context) => [
                  for (final value in ReaderMode.values)
                    PopupMenuItem(value: value, child: Text(value.label)),
                ],
              ),
              IconButton(
                tooltip: 'Ajouter un signet',
                icon: const Icon(Icons.bookmark_border),
                onPressed: () =>
                    showNotIntegrated(context, 'Signets', 'PDF-02'),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: !item.isSample
                    ? _PagesNotRendered(item: item, mode: mode)
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        children: [
                          if (item.isSample)
                            const SampleDataBanner(
                              message:
                                  'Texte d’exemple : ce n’est pas l’extraction '
                                  'd’un vrai PDF. Le moteur PDF local n’est pas '
                                  'encore intégré.',
                            ),
                          const SizedBox(height: 20),
                          Text(
                            'Chapter 3\nLearning',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              color: mode.text,
                            ),
                          ),
                          const SizedBox(height: 20),
                          for (final paragraph in _sampleChapter) ...[
                            SelectableText(
                              paragraph,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: mode.text,
                                height: 1.6,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.spaceAround,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _ReaderAction(
                                icon: Icons.border_color_outlined,
                                label: 'Surligner',
                                color: mode.text,
                                onTap: () => showNotIntegrated(
                                  context,
                                  'Surlignage',
                                  'PDF-02',
                                ),
                              ),
                              _ReaderAction(
                                icon: Icons.translate,
                                label: 'Traduire',
                                color: mode.text,
                                onTap: () => showNotIntegrated(
                                  context,
                                  'Traduction de sélection',
                                  'TR-02',
                                ),
                              ),
                              _ReaderAction(
                                icon: Icons.sticky_note_2_outlined,
                                label: 'Note',
                                color: mode.text,
                                onTap: () => showNotIntegrated(
                                  context,
                                  'Notes',
                                  'PDF-02',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
              const _AudioPanel(),
            ],
          ),
        );
      },
    );
  }
}

class _ReaderAction extends StatelessWidget {
  const _ReaderAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(foregroundColor: color),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon), const SizedBox(height: 4), Text(label)],
      ),
    );
  }
}

/// Panneau audio fixe. Les commandes restent désactivées tant que la
/// synthèse vocale locale (TTS-01) n'est pas intégrée.
class _AudioPanel extends StatelessWidget {
  const _AudioPanel();

  @override
  Widget build(BuildContext context) {
    final tts = AppScope.of(context).engines.tts;
    const panel = MurmureColors.deepGreen;
    const onPanel = Colors.white;
    final disabled = onPanel.withValues(alpha: 0.45);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.record_voice_over_outlined, color: onPanel),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tts.isAvailable
                        ? 'Voix douce'
                        : 'Lecture à voix haute : non disponible '
                              '(${tts.ticket})',
                    style: const TextStyle(color: onPanel),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Reculer de 15 secondes',
                  onPressed: null,
                  icon: Icon(Icons.replay, color: disabled),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  tooltip: 'Lire',
                  onPressed: null,
                  iconSize: 32,
                  icon: Icon(Icons.play_arrow, color: disabled),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Avancer de 15 secondes',
                  onPressed: null,
                  icon: Icon(Icons.forward_outlined, color: disabled),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Document réel importé : le fichier est bien stocké, mais l'affichage des
/// pages attend l'intégration du moteur PDF.
class _PagesNotRendered extends StatelessWidget {
  const _PagesNotRendered({required this.item, required this.mode});

  final LibraryItem item;
  final ReaderMode mode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium?.copyWith(color: mode.text);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      children: [
        Icon(Icons.picture_as_pdf_outlined, size: 56, color: mode.text),
        const SizedBox(height: 16),
        Text(
          'Affichage des pages pas encore disponible',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(color: mode.text),
        ),
        const SizedBox(height: 12),
        Text(
          'Ce PDF est bien enregistré dans l’espace privé de Murmure '
          '(${describeLibraryItem(item)}). Le rendu des pages et '
          'l’extraction du texte arrivent avec le moteur PDF local.',
          textAlign: TextAlign.center,
          style: style,
        ),
      ],
    );
  }
}
