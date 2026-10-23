import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_scope.dart';
import '../../core/router/app_router.dart';
import '../../domain/models/library_item.dart';
import '../library/import_pdf.dart';
import '../widgets/developer_credit.dart';
import '../widgets/empty_state.dart';
import '../widgets/library_item_icon.dart';
import '../widgets/sample_data_banner.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = AppScope.of(context).library;
    final theme = Theme.of(context);

    return SafeArea(
      child: ListenableBuilder(
        listenable: library,
        builder: (context, _) {
          final lastRead = library.lastRead;
          final recents = library.items.take(3).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.eco_outlined,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Murmure',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Paramètres',
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => context.push(AppRoutes.settings),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Bonjour', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                'Votre espace de lecture et d’apprentissage',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (library.containsSampleData) ...[
                const SizedBox(height: 16),
                const SampleDataBanner(),
              ],
              if (lastRead != null) ...[
                const SizedBox(height: 16),
                _ResumeCard(item: lastRead),
              ] else if (library.items.isEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  child: EmptyState(
                    icon: Icons.menu_book_outlined,
                    title: 'Votre bibliothèque est vide',
                    message:
                        'Importez un PDF : il est copié dans l’espace '
                        'privé de Murmure, sur ce téléphone.',
                    action: FilledButton.icon(
                      icon: const Icon(Icons.upload_file_outlined),
                      label: const Text('Importer un PDF'),
                      onPressed: () => importPdf(context),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text('Accès rapides', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.4,
                children: [
                  _QuickAction(
                    icon: Icons.upload_file_outlined,
                    label: 'Importer PDF',
                    onTap: () => importPdf(context),
                  ),
                  _QuickAction(
                    icon: Icons.mic_none,
                    label: 'Enregistrer',
                    onTap: () => context.go(AppRoutes.transcription),
                  ),
                  _QuickAction(
                    icon: Icons.explore_outlined,
                    label: 'Découvrir',
                    onTap: () => context.go(AppRoutes.discover),
                  ),
                  _QuickAction(
                    icon: Icons.menu_book_outlined,
                    label: 'Bibliothèque',
                    onTap: () => context.go(AppRoutes.library),
                  ),
                ],
              ),
              if (recents.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Documents récents', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
              ],
              for (final item in recents)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: LibraryItemIcon(type: item.type, size: 40),
                  title: Text(item.title),
                  subtitle: Text(describeLibraryItem(item)),
                  trailing: item.isSample ? const SampleTag() : null,
                  onTap: item.type == LibraryItemType.pdf
                      ? () => context.push(AppRoutes.reader(item.id))
                      : null,
                ),
              const SizedBox(height: 24),
              Text(
                'Chaque lecture est une nouvelle découverte.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              const Center(child: DeveloperCredit()),
            ],
          );
        },
      ),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.item});

  final LibraryItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reprendre ma lecture', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                LibraryItemIcon(type: item.type, size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      if (item.progress != null) ...[
                        Text('Page ${item.currentPage} sur ${item.pageCount}'),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: item.progress,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                          semanticsLabel: 'Progression de lecture',
                        ),
                      ] else if (item.lastOpenedAt != null)
                        Text('Ouvert le ${formatDate(item.lastOpenedAt!)}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.menu_book),
                label: const Text('Continuer la lecture'),
                onPressed: () => context.push(AppRoutes.reader(item.id)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
    );
  }
}
