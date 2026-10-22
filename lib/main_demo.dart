import 'package:flutter/material.dart';

import 'app.dart';
import 'core/app_scope.dart';

/// Démonstration dans le navigateur : bibliothèque d'exemple en mémoire,
/// signalée comme telle à l'écran. Ce n'est pas l'application du téléphone.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    AppScope(dependencies: AppDependencies.sample(), child: const MurmureApp()),
  );
}
