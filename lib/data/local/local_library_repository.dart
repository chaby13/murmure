import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../domain/models/library_item.dart';
import '../../domain/models/picked_document.dart';
import '../../domain/services/library_repository.dart';
import '../../domain/services/local_engines.dart';
import 'library_database.dart';

/// Bibliothèque réelle : métadonnées en SQLite, fichiers copiés dans le
/// dossier privé de l'application. Rien ne sort de l'appareil.
class LocalLibraryRepository extends LibraryRepository {
  LocalLibraryRepository._(this._db, this._documentsDir, this._pdf);

  static Future<LocalLibraryRepository> open({
    required String databasePath,
    required Directory documentsDir,
    required PdfEngine pdfEngine,
    DatabaseFactory? factory,
  }) async {
    await documentsDir.create(recursive: true);
    final db = await openLibraryDatabase(databasePath, factory: factory);
    final repository = LocalLibraryRepository._(db, documentsDir, pdfEngine);
    await repository._reload();
    return repository;
  }

  final Database _db;
  final Directory _documentsDir;
  final PdfEngine _pdf;
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

  @override
  File? fileOf(LibraryItem item) {
    final name = item.fileName;
    return name == null ? null : File(p.join(_documentsDir.path, name));
  }

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
      // Sans moteur PDF, le nombre de pages reste inconnu.
      final pageCount = _pdf.isAvailable
          ? await _pdf.pageCount(copy.path)
          : null;
      final now = DateTime.now();
      await _db.insert('items', {
        'id': id,
        'title': _titleFrom(document.name),
        'type': LibraryItemType.pdf.name,
        'file_name': fileName,
        'size_bytes': await copy.length(),
        'page_count': pageCount,
        'is_favorite': 0,
        'added_at': now.millisecondsSinceEpoch,
      });
    } on PdfOpenException catch (e) {
      await copy.delete();
      throw ImportException(e.message);
    } catch (_) {
      await copy.delete();
      rethrow;
    }
    await _reload();
    return byId(id)!;
  }

  @override
  Future<LibraryItem> addAudio(
    String sourcePath, {
    required String title,
    Duration? duration,
    bool move = false,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw const ImportException('Le fichier audio est introuvable.');
    }
    final id = _newId();
    var extension = p.extension(sourcePath).toLowerCase();
    if (extension.isEmpty) extension = '.audio';
    final fileName = '$id$extension';
    final target = p.join(_documentsDir.path, fileName);
    final copy = move
        ? await _moveFile(source, target)
        : await source.copy(target);
    await _insert(
      id: id,
      title: title,
      type: LibraryItemType.audio,
      fileName: fileName,
      sizeBytes: await copy.length(),
      // La durée réelle du WAV prime sur celle mesurée pendant l'enregistrement.
      duration: await wavDuration(copy) ?? duration,
    );
    return byId(id)!;
  }

  @override
  Future<LibraryItem> addTranscription({
    required String title,
    required String text,
  }) async {
    final id = _newId();
    final fileName = '$id.txt';
    final file = File(p.join(_documentsDir.path, fileName));
    await file.writeAsString(text, flush: true);
    await _insert(
      id: id,
      title: title,
      type: LibraryItemType.transcription,
      fileName: fileName,
      sizeBytes: await file.length(),
    );
    return byId(id)!;
  }

  @override
  Future<String> readText(String id) async {
    final item = byId(id);
    final file = item == null ? null : fileOf(item);
    if (file == null || !await file.exists()) {
      throw const ImportException('Cette transcription est introuvable.');
    }
    return file.readAsString();
  }

  @override
  Future<void> saveText(String id, String text) async {
    final item = byId(id);
    final file = item == null ? null : fileOf(item);
    if (file == null) return;
    await file.writeAsString(text, flush: true);
    await _db.update(
      'items',
      {'size_bytes': await file.length()},
      where: 'id = ?',
      whereArgs: [id],
    );
    await _reload();
  }

  Future<void> _insert({
    required String id,
    required String title,
    required LibraryItemType type,
    required String fileName,
    required int sizeBytes,
    Duration? duration,
  }) async {
    await _db.insert('items', {
      'id': id,
      'title': title,
      'type': type.name,
      'file_name': fileName,
      'size_bytes': sizeBytes,
      'duration_ms': duration?.inMilliseconds,
      'is_favorite': 0,
      'added_at': DateTime.now().millisecondsSinceEpoch,
    });
    await _reload();
  }

  /// Le dossier temporaire peut être sur un autre volume : on copie alors
  /// puis on efface.
  static Future<File> _moveFile(File source, String target) async {
    try {
      return await source.rename(target);
    } on FileSystemException {
      final copy = await source.copy(target);
      await source.delete();
      return copy;
    }
  }

  @override
  Future<void> delete(String id) async {
    final item = byId(id);
    if (item == null) return;
    await _db.delete('items', where: 'id = ?', whereArgs: [id]);
    final file = fileOf(item);
    if (file != null && await file.exists()) await file.delete();
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

  @override
  Future<void> savePage(String id, int page) async {
    final item = byId(id);
    if (item == null || item.currentPage == page) return;
    await _db.update(
      'items',
      {'current_page': page},
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

  /// Durée d'un fichier WAV d'après son en-tête, null pour un autre format.
  static Future<Duration?> wavDuration(File file) async {
    final head = <int>[];
    await for (final chunk in file.openRead(0, 44)) {
      head.addAll(chunk);
    }
    if (head.length < 44 ||
        String.fromCharCodes(head.sublist(0, 4)) != 'RIFF' ||
        String.fromCharCodes(head.sublist(8, 12)) != 'WAVE') {
      return null;
    }
    final byteRate = head[28] | head[29] << 8 | head[30] << 16 | head[31] << 24;
    if (byteRate == 0) return null;
    final dataBytes = await file.length() - 44;
    return Duration(milliseconds: dataBytes * 1000 ~/ byteRate);
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
