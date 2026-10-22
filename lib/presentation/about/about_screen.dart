import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/app_info.dart';
import '../../core/router/app_router.dart';
import '../widgets/chabane_logo.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  // La version vient de la configuration de build (pubspec.yaml), jamais
  // d'une valeur codée en dur.
  late final Future<PackageInfo> _info = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('À propos')),
      body: FutureBuilder<PackageInfo>(
        future: _info,
        builder: (context, snapshot) {
          final info = snapshot.data;
          final version = info == null
              ? 'Version…'
              : 'Version ${info.version} (build ${info.buildNumber})';
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              const Center(child: ChabaneLogo(width: 140)),
              const SizedBox(height: 24),
              Text(
                'Murmure',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(version, textAlign: TextAlign.center, style: muted),
              const SizedBox(height: 4),
              Text(
                'Développé par ${AppInfo.developerName}',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notre promesse',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Murmure est conçu pour lire, transcrire et traduire '
                        'vos documents sur votre téléphone, sans compte et '
                        'sans cloud.',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cette version est un squelette de développement : '
                        'les moteurs locaux ne sont pas encore intégrés et '
                        'l’audit réseau n’a pas encore été réalisé.',
                        style: muted,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Politique de confidentialité'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.privacy),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.gavel_outlined),
                title: const Text('Licences tierces'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'Murmure',
                  applicationVersion: info?.version,
                  applicationLegalese: '© ${AppInfo.developerName}',
                ),
              ),
              if (AppInfo.developerWebsite.isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.language),
                  title: const Text('Site du développeur'),
                  subtitle: const Text(AppInfo.developerWebsite),
                ),
              if (AppInfo.developerContact.isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.mail_outline),
                  title: const Text('Nous contacter'),
                  subtitle: const Text(AppInfo.developerContact),
                ),
            ],
          );
        },
      ),
    );
  }
}
