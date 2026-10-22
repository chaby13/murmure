import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../domain/models/library_item.dart';
import '../../domain/models/picked_document.dart';
import '../../domain/services/library_repository.dart';
import 'library_database.dart';

/// Bibliothèque réelle : métadonnées en SQLite, fichiers copiés dans le
/// dossier privé de l'application. Rien ne sort de l'appareil.
class LocalLibraryRepository extends LibraryRepository {
  LocalLibraryRepository._(this._db, this._documentsDir);

  static Future<LocalLibraryRepository> open({
    required String databasePath,
    required Directory documentsDir,
    DatabaseFactory? factory,
  }) async {
    await documentsDir.create(recursive: true);
    final db = await openLibraryDatabase(databasePath, factory: factory);
    final repository = LocalLibraryRepository._(db, documentsDir);
    await repository._reload();
    return repository;
  }

  final Database _db;
  final Directory _documentsDir;
  List<LibraryItem> _items = const [];

  static final _random = Random.secure();

  @override
  List<LibraryItem> get items => _items;

  @override
  bool get containsSampleData => false;

  @override
  LibraryItem? byId(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  LibraryItem? get lastRead {
    LibraryItem? latest;
    for (final item in _items) {
      final opened = item.lastOpenedAt;
      if (item.type != LibraryItemType.pdf || opened == null) continue;
      if (latest == null || opened.isAfter(latest.lastOpenedAt!)) latest = item;
    }
    return latest;
  }

  /// Chemin du fichier d'un élément dans le stockage privé.
  File fileOf(LibraryItem item) =>
      File(p.join(_documentsDir.path, item.fileName));

  @override
  Future<LibraryItem> importPdf(PickedDocument document) async {
    final source = File(document.path);
    if (!await source.exists()) {
      throw const ImportException('Le fichier choisi est introuvable.');
    }
    if (!await _looksLikePdf(source)) {
      throw ImportException('« ${document.name} » n’est pas un PDF valide.');
    }

    final id = _newId();
    final fileName = '$id.pdf';
    final copy = await source.copy(p.join(_documentsDir.path, fileName));
    try {
      final now = DateTime.now();
      await _db.insert('items', {
        'id': id,
        'title': _titleFrom(document.name),
        'type': LibraryItemType.pdf.name,
        'file_name': fileName,
        'size_bytes': await copy.length(),
        'is_favorite': 0,
        'added_at': now.millisecondsSinceEpoch,
      });
    } catch (_) {
      await copy.delete();
      rethrow;
    }
    await _reload();
    return byId(id)!;
  }

  @override
  Future<void> delete(String id) async {
    final item = byId(id);
    if (item == null) return;
    await _db.delete('items', where: 'id = ?', whereArgs: [id]);
    if (item.fileName != null) {
      final file = fileOf(item);
      if (await file.exists()) await file.delete();
    }
    await _reload();
  }

  @override
  Future<void> toggleFavorite(String id) async {
    final item = byId(id);
    if (item == null) return;
    await _db.update(
      'items',
      {'is_favorite': item.isFavorite ? 0 : 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    await _reload();
  }

  @override
  Future<void> markOpened(String id) async {
    await _db.update(
      'items',
      {'last_opened_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
    await _reload();
  }

  Future<void> close() => _db.close();

  Future<void> _reload() async {
    final rows = await _db.query('items', orderBy: 'added_at DESC');
    _items = [for (final row in rows) _fromRow(row)];
    notifyListeners();
  }

  static LibraryItem _fromRow(Map<String, Object?> row) {
    DateTime? date(Object? ms) =>
        ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms as int);
    final durationMs = row['duration_ms'] as int?;
    return LibraryItem(
      id: row['id']! as String,
      title: row['title']! as String,
      type: LibraryItemType.values.byName(row['type']! as String),
      fileName: row['file_name'] as String?,
      sizeBytes: row['size_bytes']! as int,
      pageCount: row['page_count'] as int?,
      currentPage: row['current_page'] as int?,
      duration: durationMs == null ? null : Duration(milliseconds: durationMs),
      isFavorite: row['is_favorite'] == 1,
      addedAt: date(row['added_at']),
      lastOpenedAt: date(row['last_opened_at']),
      isSample: false,
    );
  }

  /// La norme PDF place l'en-tête « %PDF- » dans le premier kilo-octet.
  static Future<bool> _looksLikePdf(File file) async {
    final head = <int>[];
    await for (final chunk in file.openRead(0, 1024)) {
      head.addAll(chunk);
    }
    return String.fromCharCodes(head).contains('%PDF-');
  }

  static String _titleFrom(String name) {
    final title = name.trim();
    return title.isEmpty ? 'Document sans titre.pdf' : title;
  }

  static String _newId() {
    final bytes = List<int>.generate(12, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
