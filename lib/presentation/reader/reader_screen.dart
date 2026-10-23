import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../core/app_scope.dart';
import '../../core/theme/murmure_colors.dart';
import '../../domain/models/library_item.dart';
import '../../domain/services/library_repository.dart';
import '../widgets/empty_state.dart';
import '../widgets/library_item_icon.dart';
import '../widgets/not_integrated.dart';
import '../widgets/sample_data_banner.dart';
import 'read_aloud_controller.dart';
import 'read_aloud_panel.dart';

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
  int? _page;
  Timer? _saveTimer;
  final _viewer = PdfViewerController();
  ReadAloudController? _reader;
  bool _readerInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_readerInitialized) return;
    _readerInitialized = true;
    final deps = AppScope.of(context);
    final item = deps.library.byId(widget.itemId);
    final file = item == null ? null : deps.library.fileOf(item);
    final pages = item?.pageCount;
    if (file == null || pages == null || !deps.engines.pdf.isAvailable) return;
    if (!deps.engines.tts.isAvailable) return;
    _reader = ReadAloudController(
      tts: deps.engines.tts,
      pdf: deps.engines.pdf,
      filePath: file.path,
      pageCount: pages,
      startPage: item!.currentPage ?? 1,
      onPageChanged: (page) {
        if (_viewer.isReady) _viewer.goToPage(pageNumber: page);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Mémorise l'ouverture pour « Reprendre ma lecture ».
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).library.markOpened(widget.itemId);
    });
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _reader?.dispose();
    super.dispose();
  }

  void _onPageChanged(LibraryRepository library, int? page) {
    if (page == null || page == _page) return;
    setState(() => _page = page);
    _reader?.followPage(page);
    // Enregistre la page quand la lecture se stabilise.
    _saveTimer?.cancel();
    _saveTimer = Timer(
      const Duration(milliseconds: 600),
      () => library.savePage(widget.itemId, page),
    );
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
    final file = deps.library.fileOf(item);
    final canRender = file != null && deps.engines.pdf.isAvailable;
    final page = _page ?? item.currentPage ?? 1;

    return ListenableBuilder(
      listenable: deps.settings,
      builder: (context, _) {
        final mode = deps.settings.readerMode;
        final theme = Theme.of(context);

        final Widget content;
        if (item.isSample) {
          content = _SampleChapter(mode: mode);
        } else if (canRender) {
          content = PdfViewer.file(
            file.path,
            controller: _viewer,
            initialPageNumber: item.currentPage ?? 1,
            params: PdfViewerParams(
              backgroundColor: mode.background,
              onPageChanged: (page) => _onPageChanged(deps.library, page),
              errorBannerBuilder: (context, error, stackTrace, ref) =>
                  const EmptyState(
                    icon: Icons.error_outline,
                    title: 'Impossible d’afficher ce PDF',
                    message:
                        'Le fichier est peut-être endommagé ou protégé '
                        'par un mot de passe.',
                  ),
            ),
          );
        } else {
          content = _PagesNotRendered(item: item, mode: mode);
        }

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
                    'Page $page sur ${item.pageCount}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: mode.text,
                    ),
                  ),
              ],
            ),
            actions: [
              if (canRender && !item.isSample)
                IconButton(
                  tooltip: 'Texte de la page',
                  icon: const Icon(Icons.notes),
                  onPressed: () => _showPageText(context, file.path, page),
                ),
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
            ],
          ),
          body: Column(
            children: [
              Expanded(child: content),
              ReadAloudPanel(
                controller: _reader,
                unavailableReason: item.isSample
                    ? 'Lecture à voix haute : importez un vrai PDF pour l’écouter.'
                    : 'Lecture à voix haute indisponible pour ce document.',
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPageText(BuildContext context, String path, int page) {
    final pdf = AppScope.of(context).engines.pdf;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (context, controller) => FutureBuilder<String>(
          future: pdf.extractPageText(path, page),
          builder: (context, snapshot) {
            final theme = Theme.of(context);
            final Widget body;
            if (snapshot.connectionState != ConnectionState.done) {
              body = const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              body = Text(
                'Le texte de cette page n’a pas pu être lu.\n'
                '${snapshot.error}',
              );
            } else if (snapshot.data!.isEmpty) {
              body = const Text(
                'Aucun texte sur cette page. S’il s’agit d’une page scannée, '
                'la reconnaissance de texte (OCR) arrivera plus tard.',
              );
            } else {
              body = SelectableText(
                snapshot.data!,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
              );
            }
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              children: [
                Text(
                  'Texte de la page $page',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                body,
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Texte de démonstration pour la bibliothèque d'exemple.
class _SampleChapter extends StatelessWidget {
  const _SampleChapter({required this.mode});

  final ReaderMode mode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        const SampleDataBanner(
          message:
              'Texte d’exemple : ce n’est pas l’extraction d’un vrai '
              'PDF.',
        ),
        const SizedBox(height: 20),
        Text(
          'Chapter 3\nLearning',
          style: theme.textTheme.headlineLarge?.copyWith(color: mode.text),
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
              onTap: () => showNotIntegrated(context, 'Surlignage', 'PDF-02'),
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
              onTap: () => showNotIntegrated(context, 'Notes', 'PDF-02'),
            ),
          ],
        ),
      ],
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
          'Affichage des pages indisponible',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(color: mode.text),
        ),
        const SizedBox(height: 12),
        Text(
          'Ce PDF est bien enregistré dans l’espace privé de Murmure '
          '(${describeLibraryItem(item)}), mais le moteur PDF local '
          'n’est pas disponible dans cette version.',
          textAlign: TextAlign.center,
          style: style,
        ),
      ],
    );
  }
}
