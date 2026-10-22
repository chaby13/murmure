import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmure/presentation/widgets/chabane_logo.dart';

import 'test_app.dart';

Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('les quatre onglets sont navigables', (tester) async {
    await pumpMurmure(tester);
    expect(find.text('Bonjour'), findsOneWidget);

    await tapTab(tester, 'Bibliothèque');
    expect(find.widgetWithText(AppBar, 'Bibliothèque'), findsOneWidget);

    await tapTab(tester, 'Transcrire');
    expect(find.widgetWithText(AppBar, 'Transcription'), findsOneWidget);

    await tapTab(tester, 'Traduire');
    expect(find.widgetWithText(AppBar, 'Traduction'), findsOneWidget);

    await tapTab(tester, 'Accueil');
    expect(find.text('Bonjour'), findsOneWidget);
  });

  testWidgets('Reprendre ma lecture ouvre le lecteur', (tester) async {
    await pumpMurmure(tester);
    await tester.tap(find.text('Continuer la lecture'));
    await tester.pumpAndSettle();
    expect(find.text('Page 48 sur 126'), findsOneWidget);
    expect(find.textContaining('Texte d’exemple'), findsOneWidget);
  });

  testWidgets('Paramètres puis À propos affichent logo et version du build', (
    tester,
  ) async {
    await pumpMurmure(tester);
    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Paramètres'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('À propos'), 200);
    await tester.tap(find.text('À propos'));
    await tester.pumpAndSettle();

    expect(find.byType(ChabaneLogo), findsOneWidget);
    expect(find.bySemanticsLabel('Logo Chabane DEV'), findsOneWidget);
    expect(find.text('Version 0.1.0 (build 1)'), findsOneWidget);
    expect(find.text('Développé par Chabane DEV'), findsOneWidget);
  });

  testWidgets('le crédit Chabane DEV est discret sur l’accueil', (
    tester,
  ) async {
    await pumpMurmure(tester);
    await tester.scrollUntilVisible(
      find.bySemanticsLabel('Conçu par Chabane DEV'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final logo = tester.getSize(find.byType(ChabaneLogo));
    expect(logo.width, lessThanOrEqualTo(24));
  });
}
