import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmure/app.dart';
import 'package:murmure/core/app_scope.dart';
import 'package:murmure/core/settings/settings_controller.dart';
import 'package:murmure/data/local/local_library_repository.dart';
import 'package:murmure/domain/models/app_language.dart';
import 'package:murmure/domain/models/library_item.dart';
import 'package:murmure/domain/models/picked_document.dart';
import 'package:murmure/domain/services/local_engines.dart';
import 'package:murmure/services/engine_registry.dart';
import 'package:murmure/services/ocr/ocr_engine_not_integrated.dart';
import 'package:murmure/services/pdf/pdf_engine_not_integrated.dart';
import 'package:murmure/services/transcription/transcription_jobs.dart';
import 'package:murmure/services/tts/tts_engine_not_integrated.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'import_flow_test.dart' show settleIo;
import 'support/fixtures.dart';

void main() {
  sqfliteFfiInit();
  late Directory root;

  Future<LocalLibraryRepository> open() => LocalLibraryRepository.open(
    databasePath: p.join(root.path, 'murmure.db'),
    documentsDir: Directory(p.join(root.path, 'documents')),
    factory: databaseFactoryFfi,
    pdfEngine: const PdfEngineNotIntegrated(),
  );

  setUp(() => root = Directory.systemTemp.createTempSync('murmure_asr_'));
  tearDown(() => root.deleteSync(recursive: true));

  group('bibliothèque', () {
    test('un enregistrement est déplacé en privé avec sa durée', () async {
      final repo = await open();
      final wav = writeWav(root, 'rec.wav', seconds: 2);
      final item = await repo.addAudio(
        wav.path,
        title: 'Réunion.wav',
        move: true,
      );

      expect(item.type, LibraryItemType.audio);
      expect(item.duration, const Duration(seconds: 2));
      expect(wav.existsSync(), isFalse);
      expect(repo.fileOf(item)!.existsSync(), isTrue);
      await repo.close();
    });

    test('une transcription se relit, se corrige et se supprime', () async {
      var repo = await open();
      final item = await repo.addTranscription(
        title: 'Réunion.txt',
        text: 'Premier jet',
      );
      expect(await repo.readText(item.id), 'Premier jet');

      await repo.saveText(item.id, 'Texte corrigé, accents compris : éàç');
      await repo.close();
      repo = await open();
      expect(
        await repo.readText(item.id),
        'Texte corrigé, accents compris : éàç',
      );

      final file = repo.fileOf(repo.byId(item.id)!)!;
      await repo.delete(item.id);
      expect(file.existsSync(), isFalse);
      await repo.close();
    });
  });

  group('TranscriptionJobs', () {
    test('range le texte obtenu dans la bibliothèque', () async {
      final repo = await open();
      final asr = FakeAsrEngine()..text = 'Hello everyone.';
      final jobs = TranscriptionJobs(library: repo, asr: asr);
      final audio = await repo.addAudio(
        writeWav(root, 'a.wav').path,
        title: 'Interview.wav',
      );

      final result = await jobs.transcribe(audio, language: AppLanguage.en);

      expect(result!.title, 'Interview.txt');
      expect(await repo.readText(result.id), 'Hello everyone.');
      expect(asr.calls.single.$2, AppLanguage.en);
      expect(jobs.current!.status, TranscriptionStatus.done);
      await repo.close();
    });

    test('un audio sans parole est signalé, rien n’est inventé', () async {
      final repo = await open();
      final jobs = TranscriptionJobs(
        library: repo,
        asr: FakeAsrEngine()..text = '',
      );
      final audio = await repo.addAudio(
        writeWav(root, 'a.wav').path,
        title: 'Silence.wav',
      );

      expect(await jobs.transcribe(audio), isNull);
      expect(jobs.current!.status, TranscriptionStatus.failed);
      expect(jobs.current!.error, contains('Aucune parole'));
      expect(
        repo.items.where((i) => i.type == LibraryItemType.transcription),
        isEmpty,
      );
      await repo.close();
    });

    test('l’erreur du moteur est affichée telle quelle', () async {
      final repo = await open();
      final jobs = TranscriptionJobs(
        library: repo,
        asr: FakeAsrEngine()
          ..failure = const AsrException('Fichier illisible.'),
      );
      final audio = await repo.addAudio(
        writeWav(root, 'a.wav').path,
        title: 'Abîmé.wav',
      );
      await jobs.transcribe(audio);
      expect(jobs.current!.error, 'Fichier illisible.');
      await repo.close();
    });
  });

  testWidgets('enregistrer, transcrire, corriger puis exporter', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final picker = FakeDocumentPicker();
    final asr = FakeAsrEngine()..text = 'Bonjour à tous.';
    final repo = (await tester.runAsync(open))!;
    addTearDown(() => tester.runAsync(repo.close));
    final recorder = FakeAudioRecorder(root);

    await tester.pumpWidget(
      AppScope(
        dependencies: AppDependencies(
          library: repo,
          settings: SettingsController(),
          engines: EngineRegistry(
            pdf: const PdfEngineNotIntegrated(),
            ocr: const OcrEngineNotIntegrated(),
            tts: const TtsEngineNotIntegrated(),
            asr: asr,
          ),
          picker: picker,
          recorder: recorder,
        ),
        child: const MurmureApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Transcrire'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('record-button')));
    await tester.pump();
    expect(recorder.recording, isTrue);
    expect(find.textContaining('Enregistrement en cours'), findsOneWidget);

    await tester.tap(find.byKey(const Key('record-button')));
    await settleIo(
      tester,
      until: () =>
          find.byKey(const Key('transcript-text')).evaluate().isNotEmpty,
    );

    // Le texte s'ouvre, modifiable.
    expect(find.text('Bonjour à tous.'), findsOneWidget);
    expect(asr.calls.single.$2, AppLanguage.fr);
    final audio = repo.items.firstWhere((i) => i.type == LibraryItemType.audio);
    expect(audio.duration, const Duration(seconds: 3));

    await tester.enterText(
      find.byKey(const Key('transcript-text')),
      'Bonjour à toutes et à tous.',
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Enregistrer les corrections'));
    await settleIo(tester);
    final transcript = repo.items.firstWhere(
      (i) => i.type == LibraryItemType.transcription,
    );
    expect(
      await tester.runAsync(() => repo.readText(transcript.id)),
      'Bonjour à toutes et à tous.',
    );

    await tester.tap(find.byTooltip('Exporter en TXT'));
    await settleIo(tester);
    expect(picker.exported, {transcript.title: 'Bonjour à toutes et à tous.'});
  });

  testWidgets('importer un fichier audio puis le transcrire', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final picker = FakeDocumentPicker();
    final asr = FakeAsrEngine()..text = 'Hello world.';
    final repo = (await tester.runAsync(open))!;
    addTearDown(() => tester.runAsync(repo.close));
    picker.nextAudio = PickedDocument(
      name: 'Cours.wav',
      path: writeWav(root, 'cours.wav').path,
    );

    await tester.pumpWidget(
      AppScope(
        dependencies: AppDependencies(
          library: repo,
          settings: SettingsController(),
          engines: EngineRegistry(
            pdf: const PdfEngineNotIntegrated(),
            ocr: const OcrEngineNotIntegrated(),
            tts: const TtsEngineNotIntegrated(),
            asr: asr,
          ),
          picker: picker,
        ),
        child: const MurmureApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Transcrire'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fichier audio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Auto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choisir un fichier'));
    await settleIo(
      tester,
      until: () =>
          find.byKey(const Key('transcript-text')).evaluate().isNotEmpty,
    );

    expect(find.text('Hello world.'), findsOneWidget);
    expect(asr.calls.single.$2, isNull);
    expect(find.text('Cours.txt'), findsOneWidget);
  });
}
