import 'package:sqflite/sqflite.dart';

/// Version courante du schéma. Toute évolution ajoute une migration à
/// [_migrations] sans jamais modifier les précédentes.
const libraryDatabaseVersion = 1;

final Map<int, Future<void> Function(Database db)> _migrations = {
  1: (db) async {
    await db.execute('''
      CREATE TABLE items (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        file_name TEXT,
        size_bytes INTEGER NOT NULL,
        page_count INTEGER,
        current_page INTEGER,
        duration_ms INTEGER,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        added_at INTEGER NOT NULL,
        last_opened_at INTEGER
      )
    ''');
  },
};

Future<Database> openLibraryDatabase(String path, {DatabaseFactory? factory}) {
  return (factory ?? databaseFactory).openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: libraryDatabaseVersion,
      onCreate: (db, version) => _migrate(db, 0, version),
      onUpgrade: _migrate,
    ),
  );
}

Future<void> _migrate(Database db, int from, int to) async {
  for (var version = from + 1; version <= to; version++) {
    await _migrations[version]!(db);
  }
}
