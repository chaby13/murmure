import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/murmure_theme.dart';

/// Écran affiché si Murmure ne peut pas démarrer. Le détail technique peut
/// être copié pour être transmis au développeur ; rien n'est envoyé.
class StartupErrorScreen extends StatelessWidget {
  const StartupErrorScreen({super.key, required this.error, this.stackTrace});

  final Object error;
  final StackTrace? stackTrace;

  @override
  Widget build(BuildContext context) {
    final details = '$error\n\n$stackTrace';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: MurmureTheme.light(),
      darkTheme: MurmureTheme.dark(),
      home: Builder(
        builder: (context) => Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Murmure n’a pas pu démarrer',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Copiez le détail ci-dessous et envoyez-le au développeur.',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.copy),
                  label: const Text('Copier le détail'),
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: details)),
                ),
                const SizedBox(height: 16),
                SelectableText(
                  details,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
