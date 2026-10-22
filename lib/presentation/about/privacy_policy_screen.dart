import 'package:flutter/material.dart';

/// Politique de confidentialité embarquée. BROUILLON : à faire relire avant
/// publication (ticket LEGAL-01).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = [
    (
      'Statut',
      'Ce texte est un brouillon de développement. Il sera finalisé et relu '
          'avant toute publication de Murmure.',
    ),
    (
      'Ce que Murmure traite',
      'Les PDF que vous importez, vos enregistrements audio, les fichiers '
          'audio importés, les transcriptions et les traductions.',
    ),
    (
      'Où ces données sont traitées',
      'Murmure est conçu pour traiter ces données uniquement sur votre '
          'téléphone. Aucun compte n’est demandé et aucun service cloud '
          'n’est utilisé.',
    ),
    (
      'Ce que Murmure ne fait pas',
      'Pas de publicité, pas d’analytique, pas d’envoi de vos documents, '
          'audios, textes ou traductions vers un serveur.',
    ),
    (
      'Vos droits',
      'Vous pourrez exporter ou supprimer toutes vos données depuis les '
          'paramètres (fonction prévue, ticket STORE-01).',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Confidentialité')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          for (final (title, body) in _sections) ...[
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(body, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}
