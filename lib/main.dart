import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import 'app.dart';
import 'core/app_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await pdfrxFlutterInitialize();
  final dependencies = await AppDependencies.local();
  runApp(AppScope(dependencies: dependencies, child: const MurmureApp()));
}
