import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../domain/services/library_repository.dart';

/// Parcours d'import : sélecteur système, copie privée, message de résultat.
Future<void> importPdf(BuildContext context) async {
  final deps = AppScope.of(context);
  final messenger = ScaffoldMessenger.of(context);
  void show(String text) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  final picked = await deps.picker.pickPdf();
  if (picked == null) return;
  try {
    final item = await deps.library.importPdf(picked);
    show('« ${item.title} » a été ajouté à la bibliothèque.');
  } on ImportException catch (e) {
    show(e.message);
  } catch (_) {
    show('L’import a échoué. Le fichier n’a pas été ajouté.');
  }
}

/// Demande confirmation puis supprime l'élément et son fichier.
Future<void> confirmDelete(
  BuildContext context,
  String id,
  String title,
) async {
  final library = AppScope.of(context).library;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Supprimer ce document ?'),
      content: Text(
        '« $title » et son fichier seront effacés de ce téléphone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
  if (confirmed == true) await library.delete(id);
}
