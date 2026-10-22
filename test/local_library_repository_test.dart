import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:murmure/data/local/local_library_repository.dart';
import 'package:murmure/domain/models/picked_document.dart';
import 'package:murmure/domain/services/library_repository.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/fixtures.dart';

void main() {
  sqfliteFfiInit();
  late Directory root;
  late Directory inbox;

  Future<LocalLibraryRepository> open() => LocalLibraryRepository.open(
    databasePath: p.join(root.path, 'murmure.db'),
    documentsDir: Directory(p.join(root.path, 'documents')),
    factory: databaseFactoryFfi,
  );

  setUp(() {
    root = Directory.systemTemp.createTempSync('murmure_test_');
    inbox = Directory(p.join(root.path, 'inbox'))..createSync();
  });
  tearDown(() => root.deleteSync(recursive: true));

  test(
    'un PDF importé est copié en privé et survit à la réouverture',
    () async {
      final source = writeFile(inbox, 'cours.pdf', minimalPdf);
      var repo = await open();
      final item = await repo.importPdf(
        PickedDocument(name: 'Cours d’anglais.pdf', path: source.path),
      );

      expect(item.title, 'Cours d’anglais.pdf');
      expect(item.isSample, isFalse);
      expect(item.sizeBytes, source.lengthSync());
      final copy = repo.fileOf(item);
      expect(copy.path, startsWith(p.join(root.path, 'documents')));
      expect(copy.readAsStringSync(), minimalPdf);

      // La copie ne dépend plus du fichier d'origine.
      source.deleteSync();
      await repo.close();
      repo = await open();
      expect(repo.items.single.title, 'Cours d’anglais.pdf');
      expect(repo.fileOf(repo.items.single).existsSync(), isTrue);
      await repo.close();
    },
  );

  test(
    'un fichier qui n’est pas un PDF est refusé sans rien laisser',
    () async {
      final fake = writeFile(inbox, 'faux.pdf', 'Ceci est du texte.');
      final repo = await open();
      await expectLater(
        repo.importPdf(PickedDocument(name: 'faux.pdf', path: fake.path)),
        throwsA(isA<ImportException>()),
      );
      expect(repo.items, isEmpty);
      expect(Directory(p.join(root.path, 'documents')).listSync(), isEmpty);
      await repo.close();
    },
  );

  test('un fichier introuvable est refusé', () async {
    final repo = await open();
    await expectLater(
      repo.importPdf(
        PickedDocument(name: 'x.pdf', path: p.join(inbox.path, 'x.pdf')),
      ),
      throwsA(isA<ImportException>()),
    );
    await repo.close();
  });

  test('la suppression efface la ligne et le fichier', () async {
    final source = writeFile(inbox, 'a.pdf', minimalPdf);
    final repo = await open();
    final item = await repo.importPdf(
      PickedDocument(name: 'a.pdf', path: source.path),
    );
    final copy = repo.fileOf(item);

    await repo.delete(item.id);
    expect(repo.items, isEmpty);
    expect(copy.existsSync(), isFalse);
    await repo.close();
  });

  test('favori et dernière ouverture sont persistés', () async {
    final a = writeFile(inbox, 'a.pdf', minimalPdf);
    final b = writeFile(inbox, 'b.pdf', minimalPdf);
    var repo = await open();
    final first = await repo.importPdf(
      PickedDocument(name: 'A.pdf', path: a.path),
    );
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repo.importPdf(PickedDocument(name: 'B.pdf', path: b.path));
    expect(repo.lastRead, isNull);

    await repo.toggleFavorite(first.id);
    await repo.markOpened(first.id);
    await repo.close();

    repo = await open();
    final reloaded = repo.byId(first.id)!;
    expect(reloaded.isFavorite, isTrue);
    expect(reloaded.lastOpenedAt, isNotNull);
    expect(repo.lastRead?.id, first.id);
    expect(repo.items.first.title, 'B.pdf', reason: 'plus récent en premier');
    await repo.close();
  });
}
