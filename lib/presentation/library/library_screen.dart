import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_scope.dart';
import '../../core/router/app_router.dart';
import '../../domain/models/library_item.dart';
import '../widgets/empty_state.dart';
import '../widgets/library_item_icon.dart';
import '../widgets/not_integrated.dart';
import '../widgets/sample_data_banner.dart';
import 'import_pdf.dart';

enum LibraryFilter {
  all('Tous'),
  pdf('PDF'),
  audio('Audios'),
  transcription('Transcriptions'),
  favorites('Favoris');

  const LibraryFilter(this.label);

  final String label;

  bool matches(LibraryItem item) => switch (this) {
    all => true,
    pdf => item.type == LibraryItemType.pdf,
    audio => item.type == LibraryItemType.audio,
    transcription => item.type == LibraryItemType.transcription,
    favorites => item.isFavorite,
  };
}

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  LibraryFilter _filter = LibraryFilter.all;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final library = AppScope.of(context).library;

    return Scaffold(
      appBar: AppBar(title: const Text('Bibliothèque')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Importer'),
        onPressed: () => importPdf(context),
      ),
      body: ListenableBuilder(
        listenable: library,
        builder: (context, _) {
          final query = _query.trim().toLowerCase();
          final visible = library.items
              .where(_filter.matches)
              .where((item) => item.title.toLowerCase().contains(query))
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
            children: [
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Rechercher un document…',
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final filter in LibraryFilter.values)
                    ChoiceChip(
                      label: Text(filter.label),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                ],
              ),
              if (library.containsSampleData) ...[
                const SizedBox(height: 12),
                const SampleDataBanner(),
              ],
              const SizedBox(height: 8),
              if (library.items.isEmpty)
                const EmptyState(
                  icon: Icons.menu_book_outlined,
                  title: 'Bibliothèque vide',
                  message:
                      'Touchez « Importer » pour ajouter un PDF depuis '
                      'ce téléphone.',
                )
              else if (visible.isEmpty)
                const EmptyState(
                  icon: Icons.search_off,
                  title: 'Aucun document',
                  message:
                      'Rien ne correspond à cette recherche ou à ce filtre.',
                )
              else
                for (final item in visible) _LibraryTile(item: item),
            ],
          );
        },
      ),
    );
  }
}

class _LibraryTile extends StatelessWidget {
  const _LibraryTile({required this.item});

  final LibraryItem item;

  @override
  Widget build(BuildContext context) {
    final library = AppScope.of(context).library;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: LibraryItemIcon(type: item.type),
      title: Text(item.title),
      subtitle: Row(
        children: [
          Flexible(child: Text(describeLibraryItem(item))),
          if (item.isSample) ...[const SizedBox(width: 8), const SampleTag()],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: item.isFavorite
                ? 'Retirer des favoris'
                : 'Ajouter aux favoris',
            icon: Icon(item.isFavorite ? Icons.star : Icons.star_border),
            onPressed: () => library.toggleFavorite(item.id),
          ),
          PopupMenuButton<String>(
            tooltip: 'Plus d’actions',
            onSelected: (_) => confirmDelete(context, item.id, item.title),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'delete', child: Text('Supprimer')),
            ],
          ),
        ],
      ),
      onTap: () => _open(context),
    );
  }

  void _open(BuildContext context) {
    switch (item.type) {
      case LibraryItemType.pdf:
        context.push(AppRoutes.reader(item.id));
      case LibraryItemType.audio:
        showNotIntegrated(context, 'Lecture audio', 'ASR-02');
      case LibraryItemType.transcription:
        showNotIntegrated(context, 'Ouverture des transcriptions', 'ASR-01');
    }
  }
}
