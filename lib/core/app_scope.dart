import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/local/local_library_repository.dart';
import '../data/sample/sample_library_repository.dart';
import '../domain/services/document_picker.dart';
import '../domain/services/library_repository.dart';
import '../services/engine_registry.dart';
import '../services/files/system_document_picker.dart';
import 'settings/settings_controller.dart';

/// Dépendances de l'application, injectées une seule fois au démarrage.
class AppDependencies {
  AppDependencies({
    required this.library,
    required this.settings,
    required this.engines,
    required this.picker,
  });

  /// Configuration réelle : bibliothèque SQLite dans le dossier privé de
  /// l'application.
  static Future<AppDependencies> local() async {
    const engines = EngineRegistry.current();
    final support = await getApplicationSupportDirectory();
    final library = await LocalLibraryRepository.open(
      databasePath: p.join(support.path, 'murmure.db'),
      documentsDir: Directory(p.join(support.path, 'documents')),
      pdfEngine: engines.pdf,
    );
    return AppDependencies(
      library: library,
      settings: SettingsController(),
      engines: engines,
      picker: const SystemDocumentPicker(),
    );
  }

  /// Démonstration : bibliothèque d'exemple en mémoire, clairement signalée.
  factory AppDependencies.sample({DocumentPicker? picker}) => AppDependencies(
    library: SampleLibraryRepository(),
    settings: SettingsController(),
    engines: const EngineRegistry.notIntegrated(),
    picker: picker ?? const SystemDocumentPicker(),
  );

  final LibraryRepository library;
  final SettingsController settings;
  final EngineRegistry engines;
  final DocumentPicker picker;
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
