import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmure/core/app_scope.dart';
import 'package:murmure/core/settings/settings_controller.dart';
import 'package:murmure/data/local/local_library_repository.dart';
import 'package:murmure/presentation/transcription/transcript_screen.dart';
import 'package:murmure/services/engine_registry.dart';
import 'package:murmure/services/pdf/pdf_engine_not_integrated.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'import_flow_test.dart' show settleIo;
import 'support/fixtures.dart';

void main() {
  sqfliteFfiInit();

  Future<(AppDependencies, String)> pumpEditor(
    WidgetTester tester,
    String text,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final root = Directory.systemTemp.createTempSync('murmure_edit_');
    addTearDown(() => root.deleteSync(recursive: true));
    final repo = (await tester.runAsync(
      () => LocalLibraryRepository.open(
        databasePath: p.join(root.path, 'murmure.db'),
        documentsDir: Directory(p.join(root.path, 'documents')),
        factory: databaseFactoryFfi,
        pdfEngine: const PdfEngineNotIntegrated(),
      ),
    ))!;
    addTearDown(() => tester.runAsync(repo.close));
    final item = (await tester.runAsync(
      () => repo.addTranscription(title: 'Note.txt', text: text),
    ))!;
    final deps = AppDependencies(
      library: repo,
      settings: SettingsController(),
      engines: const EngineRegistry.notIntegrated(),
      picker: FakeDocumentPicker(),
    );
    await tester.pumpWidget(
      AppScope(
        dependencies: deps,
        child: MaterialApp(home: TranscriptScreen(itemId: item.id)),
      ),
    );
    await settleIo(
      tester,
      until: () => find.textContaining('à vérifier').evaluate().isNotEmpty,
    );
    return (deps, item.id);
  }

  String editorText(WidgetTester tester) => tester
      .widget<TextField>(find.byKey(const Key('transcript-text')))
      .controller!
      .text;

  testWidgets('un mot souligné se corrige en touchant une suggestion', (
    tester,
  ) async {
    await pumpEditor(tester, 'Le chatt dort dans la maison.');
    expect(find.text('1 mot à vérifier'), findsOneWidget);

    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('suggestion-bar')), findsOneWidget);
    await tester.tap(find.widgetWithText(ActionChip, 'chat'));
    await tester.pumpAndSettle();

    expect(editorText(tester), 'Le chat dort dans la maison.');
    expect(find.text('Aucun mot à vérifier'), findsOneWidget);
  });

  testWidgets('ajouter un nom propre au dictionnaire personnel', (
    tester,
  ) async {
    final (deps, _) = await pumpEditor(tester, 'Merci Chabane pour tout.');
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajouter au dictionnaire'));
    await tester.pumpAndSettle();
    expect(deps.settings.personalWords, ['Chabane']);
    expect(find.text('Aucun mot à vérifier'), findsOneWidget);
  });

  testWidgets('typographie, rechercher et remplacer, analyse', (tester) async {
    await pumpEditor(tester, 'il fait beau .il dit "bonjour" !');

    await tester.tap(find.byTooltip('Plus d’actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Corriger la typographie'));
    await tester.pumpAndSettle();
    expect(editorText(tester), 'Il fait beau. Il dit « bonjour » !');

    await tester.tap(find.byTooltip('Rechercher et remplacer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('find-input')), 'beau');
    await tester.enterText(find.byKey(const Key('replace-input')), 'chaud');
    await tester.pump();
    expect(find.text('1/1'), findsOneWidget);
    await tester.tap(find.text('Tout'));
    await tester.pumpAndSettle();
    expect(editorText(tester), startsWith('Il fait chaud.'));

    await tester.tap(find.byTooltip('Analyse du texte'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('analysis-sheet')), findsOneWidget);
    expect(find.text('Temps d’écoute'), findsOneWidget);
  });
}
