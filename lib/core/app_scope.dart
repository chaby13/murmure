import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../data/local/local_library_repository.dart';
import '../data/sample/sample_library_repository.dart';
import '../domain/services/audio_recorder.dart';
import '../domain/services/document_picker.dart';
import '../domain/services/library_repository.dart';
import '../domain/services/link_opener.dart';
import '../services/asr/whisper_asr_engine.dart';
import '../services/audio/system_audio_recorder.dart';
import '../services/engine_registry.dart';
import '../services/tts/piper_tts_engine.dart';
import '../services/files/system_document_picker.dart';
import '../services/links/browser_link_opener.dart';
import '../services/spelling/dictionaries.dart';
import '../services/transcription/transcription_jobs.dart';
import 'settings/settings_controller.dart';

/// Dépendances de l'application, injectées une seule fois au démarrage.
class AppDependencies {
  AppDependencies({
    required this.library,
    required this.settings,
    required this.engines,
    required this.picker,
    this.recorder = const NoAudioRecorder(),
    this.links = const BrowserLinkOpener(),
  }) : transcriptions = TranscriptionJobs(
         library: library,
         asr: engines.asr,
         vocabulary: () => settings.personalWords,
       ),
       spelling = SpellingDictionaries();

  /// Configuration réelle : bibliothèque SQLite dans le dossier privé de
  /// l'application.
  static Future<AppDependencies> local() async {
    final engines = EngineRegistry.current(
      asr: await WhisperAsrEngine.load(),
      naturalVoices: await PiperTtsEngine.load(),
    );
    final support = await getApplicationSupportDirectory();
    final library = await LocalLibraryRepository.open(
      databasePath: p.join(support.path, 'murmure.db'),
      documentsDir: Directory(p.join(support.path, 'documents')),
      pdfEngine: engines.pdf,
      // Sur ordinateur (version de test Windows), SQLite passe par FFI.
      factory: Platform.isWindows || Platform.isLinux
          ? _desktopDatabase()
          : null,
    );
    return AppDependencies(
      library: library,
      settings: await SettingsController.load(
        File(p.join(support.path, 'reglages.json')),
      ),
      engines: engines,
      picker: const SystemDocumentPicker(),
      recorder: SystemAudioRecorder(),
    );
  }

  /// Démonstration : bibliothèque d'exemple en mémoire, clairement signalée.
  factory AppDependencies.sample({DocumentPicker? picker, LinkOpener? links}) =>
      AppDependencies(
        library: SampleLibraryRepository(),
        settings: SettingsController(),
        engines: const EngineRegistry.notIntegrated(),
        picker: picker ?? const SystemDocumentPicker(),
        links: links ?? const BrowserLinkOpener(),
      );

  final LibraryRepository library;
  final SettingsController settings;
  final EngineRegistry engines;
  final DocumentPicker picker;
  final AudioRecorderService recorder;
  final LinkOpener links;
  final TranscriptionJobs transcriptions;
  final SpellingDictionaries spelling;
}

DatabaseFactory _desktopDatabase() {
  sqfliteFfiInit();
  return databaseFactoryFfi;
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.dependencies, required super.child});

  final AppDependencies dependencies;

  static AppDependencies of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope introuvable dans l’arbre de widgets.');
    return scope!.dependencies;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      dependencies != oldWidget.dependencies;
}
