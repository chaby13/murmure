import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_scope.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/murmure_colors.dart';
import '../widgets/developer_credit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deps = AppScope.of(context);
    final settings = deps.settings;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            const _SectionTitle('Apparence'),
            SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('Système')),
                ButtonSegment(value: ThemeMode.light, label: Text('Clair')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Sombre')),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (value) => settings.themeMode = value.first,
            ),
            const SizedBox(height: 16),
            Text('Mode du lecteur', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<ReaderMode>(
              showSelectedIcon: false,
              segments: [
                for (final mode in ReaderMode.values)
                  ButtonSegment(value: mode, label: Text(mode.label)),
              ],
              selected: {settings.readerMode},
              onSelectionChanged: (value) => settings.readerMode = value.first,
            ),
            const SizedBox(height: 8),
            Text(
              'Ces choix ne sont pas encore mémorisés après fermeture de l’app.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const _SectionTitle('Voix et lecture'),
            ListTile(
              enabled: false,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.record_voice_over_outlined),
              title: const Text('Profils de voix, vitesse, pauses'),
              subtitle: Text(
                'Disponibles quand la synthèse locale sera intégrée '
                '(${deps.engines.tts.ticket}).',
              ),
            ),
            const _SectionTitle('Moteurs locaux'),
            for (final engine in deps.engines.all)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(engine.label),
                subtitle: Text('Ticket ${engine.ticket}'),
                trailing: Chip(
                  label: Text(
                    engine.isAvailable ? 'Disponible' : 'Non intégré',
                  ),
                ),
              ),
            const _SectionTitle('Confidentialité'),
            Text(
              'Murmure est conçu pour fonctionner sans compte ni cloud. '
              'L’audit réseau sur téléphone n’a pas encore été réalisé.',
              style: theme.textTheme.bodyMedium,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Politique de confidentialité'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.privacy),
            ),
            const _SectionTitle('Murmure'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.info_outline),
              title: const Text('À propos'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.about),
            ),
            const SizedBox(height: 24),
            const Center(child: DeveloperCredit()),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
