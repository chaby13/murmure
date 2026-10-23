import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import 'app.dart';
import 'core/app_scope.dart';
import 'presentation/startup_error_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await pdfrxFlutterInitialize();
    final dependencies = await AppDependencies.local();
    runApp(AppScope(dependencies: dependencies, child: const MurmureApp()));
  } catch (error, stackTrace) {
    // Un échec au démarrage affiche son message au lieu d'un écran figé.
    runApp(StartupErrorScreen(error: error, stackTrace: stackTrace));
  }
}
