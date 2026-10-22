import 'package:flutter/widgets.dart';

import '../data/sample/sample_library_repository.dart';
import '../domain/services/library_repository.dart';
import '../services/engine_registry.dart';
import 'settings/settings_controller.dart';

/// Dépendances de l'application, injectées une seule fois au démarrage.
class AppDependencies {
  AppDependencies({
    required this.library,
    required this.settings,
    required this.engines,
  });

  /// Configuration du squelette : bibliothèque d'exemple et moteurs non
  /// intégrés.
  factory AppDependencies.skeleton() => AppDependencies(
    library: SampleLibraryRepository(),
    settings: SettingsController(),
    engines: const EngineRegistry.notIntegrated(),
  );

  final LibraryRepository library;
  final SettingsController settings;
  final EngineRegistry engines;
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
