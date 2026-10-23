import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmure/app.dart';
import 'package:murmure/core/app_scope.dart';
import 'package:murmure/core/settings/settings_controller.dart';
import 'package:murmure/data/local/local_library_repository.dart';
import 'package:murmure/domain/models/picked_document.dart';
import 'package:murmure/services/engine_registry.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/fixtures.dart';

/// SQLite et les fichiers répondent hors de l'horloge simulée du test :
/// on alterne temps réel et images jusqu'à ce que les opérations aboutissent.
/// [until] prolonge l'attente (5 s au plus) sur une machine lente.
Future<void> settleIo(WidgetTester tester, {bool Function()? until}) async {
  for (var i = 0; i < 10 || (until != null && !until() && i < 170); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  sqfliteFfiInit();

  testWidgets('importer un PDF, le retrouver, l’ouvrir puis le supprimer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final root = Directory.systemTemp.createTempSync('murmure_ui_');
    addTearDown(() => root.deleteSync(recursive: true));
    final picker = FakeDocumentPicker();

    final repo = (await tester.runAsync(
      () => LocalLibraryRepository.open(
        databasePath: p.join(root.path, 'murmure.db'),
        documentsDir: Directory(p.join(root.path, 'documents')),
        factory: databaseFactoryFfi,
        pdfEngine: const EngineRegistry.notIntegrated().pdf,
      ),
    ))!;
    addTearDown(() => tester.runAsync(repo.close));

    await tester.pumpWidget(
      AppScope(
        dependencies: AppDependencies(
          library: repo,
          settings: SettingsController(),
          engines: const EngineRegistry.notIntegrated(),
          picker: picker,
        ),
        child: const MurmureApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Bibliothèque réelle vide : aucun exemple affiché.
    expect(find.text('Votre bibliothèque est vide'), findsOneWidget);
    expect(find.textContaining('Données d’exemple'), findsNothing);

    // Annuler le sélecteur ne fait rien.
    await tester.tap(find.text('Importer un PDF'));
    await tester.pumpAndSettle();
    expect(repo.items, isEmpty);

    final source = writeFile(root, 'source.pdf', minimalPdf);
    picker.next = PickedDocument(
      name: 'English Stories.pdf',
      path: source.path,
    );
    await tester.tap(find.text('Importer un PDF'));
    await settleIo(tester);
    expect(
      find.textContaining('a été ajouté à la bibliothèque'),
      findsOneWidget,
    );
    expect(repo.items.single.title, 'English Stories.pdf');

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Bibliothèque'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('English Stories.pdf'), findsOneWidget);
    expect(find.text('Exemple'), findsNothing);

    // Ouvrir : le lecteur dit honnêtement que le rendu n'est pas prêt.
    await tester.tap(find.text('English Stories.pdf'));
    await settleIo(tester, until: () => repo.lastRead != null);
    expect(find.text('Affichage des pages indisponible'), findsOneWidget);
    expect(repo.lastRead?.title, 'English Stories.pdf');
    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();

    // Supprimer avec confirmation.
    await tester.tap(find.byTooltip('Plus d’actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer ce document ?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
    await settleIo(tester);
    expect(repo.items, isEmpty);
    expect(find.text('Bibliothèque vide'), findsOneWidget);
  });
}
