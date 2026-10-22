import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmure/domain/models/app_language.dart';
import 'package:murmure/domain/services/local_engines.dart';
import 'package:murmure/services/engine_registry.dart';

import 'test_app.dart';

/// Garde-fou du cahier des charges : aucune fonction non implémentée ne doit
/// être présentée comme opérationnelle.
void main() {
  test('aucun moteur ne se déclare disponible dans le squelette', () {
    const engines = EngineRegistry.notIntegrated();
    for (final engine in engines.all) {
      expect(engine.isAvailable, isFalse, reason: engine.label);
    }
  });

  test('les moteurs non intégrés refusent au lieu de simuler', () {
    const engines = EngineRegistry.notIntegrated();
    expect(
      () => engines.translation.translate(
        'Hello',
        from: AppLanguage.en,
        to: AppLanguage.fr,
      ),
      throwsA(isA<EngineNotIntegratedException>()),
    );
    expect(
      () => engines.asr.transcribe('a.wav'),
      throwsA(isA<EngineNotIntegratedException>()),
    );
    expect(
      () => engines.tts.speak('Bonjour', language: AppLanguage.fr),
      throwsA(isA<EngineNotIntegratedException>()),
    );
    expect(
      () => engines.pdf.extractPageText('a.pdf', 0),
      throwsA(isA<EngineNotIntegratedException>()),
    );
    expect(
      () => engines.ocr.recognizePage('a.pdf', 0),
      throwsA(isA<EngineNotIntegratedException>()),
    );
  });

  testWidgets('Traduire ne produit aucune fausse traduction', (tester) async {
    await pumpMurmure(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Traduire'),
      ),
    );
    await tester.pumpAndSettle();

    const original = 'Learning a new language opens new doors.';
    await tester.enterText(find.byType(TextField), original);
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Traduire'));
    await tester.pumpAndSettle();

    final output = find.byKey(const Key('translation-output'));
    expect(
      find.descendant(of: output, matching: find.textContaining('non intégré')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: output, matching: find.byType(SelectableText)),
      findsNothing,
    );
  });

  testWidgets('les données d’exemple sont signalées', (tester) async {
    final deps = await pumpMurmure(tester);
    expect(deps.library.items.every((item) => item.isSample), isTrue);
    expect(find.textContaining('Données d’exemple'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Bibliothèque'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Données d’exemple'), findsOneWidget);
    expect(find.text('Exemple'), findsWidgets);
  });
}
