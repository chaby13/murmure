import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../domain/models/free_resource.dart';

/// Radios, livres et livres audio gratuits, ouverts dans le navigateur.
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  Future<void> _open(BuildContext context, FreeResource resource) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await AppScope.of(context).links.open(resource.url);
    if (!opened) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Impossible d’ouvrir ${resource.host}. Vérifiez qu’un navigateur '
            'est installé.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Découvrir')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Card(
            key: const Key('discover-notice'),
            color: theme.colorScheme.secondaryContainer,
            child: const ListTile(
              leading: Icon(Icons.public),
              title: Text('Sites gratuits, hors de Murmure'),
              subtitle: Text(
                'Ces liens s’ouvrent dans votre navigateur et demandent '
                'internet. Murmure ne se connecte jamais et ne leur transmet '
                'rien.',
              ),
            ),
          ),
          for (final section in freeResourceSections) ...[
            const SizedBox(height: 20),
            Text(section.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(
              section.hint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            for (final resource in section.resources)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(resource.name),
                  subtitle: Text('${resource.description}\n${resource.host}'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _open(context, resource),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
