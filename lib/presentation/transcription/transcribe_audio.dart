import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_scope.dart';
import '../../core/router/app_router.dart';
import '../../domain/models/app_language.dart';
import '../../domain/models/library_item.dart';

/// Choix FR / EN / Auto (null = détection automatique).
class LanguageChoice extends StatelessWidget {
  const LanguageChoice({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AppLanguage? value;
  final ValueChanged<AppLanguage?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<AppLanguage?>(
      showSelectedIcon: false,
      segments: [
        for (final language in AppLanguage.values)
          ButtonSegment(value: language, label: Text(language.label)),
        const ButtonSegment(value: null, label: Text('Auto')),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

/// Transcrit [audio] puis ouvre le texte obtenu. En cas d'échec, l'erreur
/// reste affichée sur l'écran Transcription.
Future<void> transcribeAndOpen(
  BuildContext context,
  LibraryItem audio, {
  AppLanguage? language,
}) async {
  final jobs = AppScope.of(context).transcriptions;
  final router = GoRouter.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final result = await jobs.transcribe(audio, language: language);
  if (result != null) {
    router.push(AppRoutes.transcript(result.id));
  } else if (jobs.current?.error case final error?) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error)));
  }
}

/// Depuis la bibliothèque : demande la langue puis transcrit.
Future<void> askAndTranscribe(BuildContext context, LibraryItem audio) async {
  AppLanguage? language = AppLanguage.fr;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Transcrire cet audio ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('« ${audio.title} »'),
            const SizedBox(height: 16),
            const Text('Langue parlée'),
            const SizedBox(height: 8),
            LanguageChoice(
              value: language,
              onChanged: (value) => setState(() => language = value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Transcrire'),
          ),
        ],
      ),
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(
    const SnackBar(
      content: Text(
        'Transcription lancée. Suivez l’avancement dans l’onglet '
        'Transcription.',
      ),
    ),
  );
  await transcribeAndOpen(context, audio, language: language);
}
