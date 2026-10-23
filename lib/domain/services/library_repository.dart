import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/library_item.dart';
import '../models/picked_document.dart';

/// Erreur d'import présentée telle quelle à l'utilisateur.
class ImportException implements Exception {
  const ImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Accès à la bibliothèque locale.
abstract class LibraryRepository extends ChangeNotifier {
  /// Du plus récent au plus ancien.
  List<LibraryItem> get items;

  /// Vrai tant que le contenu provient de données d'exemple.
  bool get containsSampleData;

  LibraryItem? byId(String id);

  /// Le dernier PDF ouvert, pour « Reprendre ma lecture ».
  LibraryItem? get lastRead;

  /// Copie le PDF dans le stockage privé de l'application et l'ajoute.
  /// Lève [ImportException] si le fichier n'est pas un PDF lisible.
  Future<LibraryItem> importPdf(PickedDocument document);

  /// Ajoute un fichier audio (enregistrement ou import). Avec [move], le
  /// fichier source est déplacé au lieu d'être copié.
  Future<LibraryItem> addAudio(
    String sourcePath, {
    required String title,
    Duration? duration,
    bool move = false,
  });

  /// Enregistre une transcription comme fichier texte privé.
  Future<LibraryItem> addTranscription({
    required String title,
    required String text,
  });

  /// Texte d'une transcription.
  Future<String> readText(String id);

  /// Remplace le texte d'une transcription (après correction).
  Future<void> saveText(String id, String text);

  /// Retire l'élément et efface son fichier du stockage privé.
  Future<void> delete(String id);

  Future<void> toggleFavorite(String id);

  Future<void> markOpened(String id);

  /// Mémorise la page en cours (à partir de 1) pour la reprise.
  Future<void> savePage(String id, int page);

  /// Fichier local de l'élément, ou null pour un exemple sans fichier.
  File? fileOf(LibraryItem item);
}
