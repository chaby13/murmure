import 'package:flutter/material.dart';

import 'app.dart';
import 'core/app_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = await AppDependencies.local();
  runApp(AppScope(dependencies: dependencies, child: const MurmureApp()));
}
