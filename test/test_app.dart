import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmure/app.dart';
import 'package:murmure/core/app_scope.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Monte l'application complète avec les dépendances du squelette, sur un
/// écran de téléphone (390 × 844).
Future<AppDependencies> pumpMurmure(WidgetTester tester) async {
  PackageInfo.setMockInitialValues(
    appName: 'Murmure',
    packageName: 'dev.chabane.murmure',
    version: '0.1.0',
    buildNumber: '1',
    buildSignature: '',
  );
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final deps = AppDependencies.sample();
  await tester.pumpWidget(
    AppScope(dependencies: deps, child: const MurmureApp()),
  );
  await tester.pumpAndSettle();
  return deps;
}
