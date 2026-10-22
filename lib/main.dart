import 'package:flutter/material.dart';

import 'app.dart';
import 'core/app_scope.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    AppScope(
      dependencies: AppDependencies.skeleton(),
      child: const MurmureApp(),
    ),
  );
}
