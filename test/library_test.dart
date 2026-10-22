import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

Future<void> openLibrary(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Bibliothèque'),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('le filtre Audios ne garde que les audios', (tester) async {
    await pumpMurmure(tester);
    await openLibrary(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Audios'));
    await tester.pumpAndSettle();
    expect(find.text('Réunion équipe.m4a'), findsOneWidget);
    expect(find.text('Interview.mp3'), findsOneWidget);
    expect(find.text('English Stories.pdf'), findsNothing);
  });

  testWidgets('la recherche filtre par titre et gère l’absence de résultat', (
    tester,
  ) async {
    await pumpMurmure(tester);
    await openLibrary(tester);
    await tester.enterText(find.byType(TextField), 'english');
    await tester.pumpAndSettle();
    expect(find.text('English Stories.pdf'), findsOneWidget);
    expect(find.text('Mes notes.pdf'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('Aucun document'), findsOneWidget);
  });

  testWidgets('ajouter un favori le fait apparaître dans Favoris', (
    tester,
  ) async {
    await pumpMurmure(tester);
    await openLibrary(tester);
    final row = find.ancestor(
      of: find.text('English Stories.pdf'),
      matching: find.byType(ListTile),
    );
    await tester.tap(
      find.descendant(of: row, matching: find.byTooltip('Ajouter aux favoris')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Favoris'));
    await tester.pumpAndSettle();
    expect(find.text('English Stories.pdf'), findsOneWidget);
    expect(find.text('The Art of Learning.pdf'), findsOneWidget);
    expect(find.text('Mes notes.pdf'), findsNothing);
  });
}
