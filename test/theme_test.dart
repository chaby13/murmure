import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmure/core/theme/murmure_colors.dart';
import 'package:murmure/core/theme/murmure_theme.dart';

import 'test_app.dart';

/// Rapport de contraste WCAG 2.x.
double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  for (final (name, theme) in [
    ('clair', MurmureTheme.light()),
    ('sombre', MurmureTheme.dark()),
  ]) {
    test('thème $name : texte lisible (AA ≥ 4,5:1)', () {
      final s = theme.colorScheme;
      expect(contrast(s.onSurface, s.surface), greaterThanOrEqualTo(4.5));
      expect(
        contrast(s.onSurfaceVariant, s.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(s.onSurfaceVariant, s.surfaceContainerLow),
        greaterThanOrEqualTo(4.5),
      );
      expect(contrast(s.onPrimary, s.primary), greaterThanOrEqualTo(4.5));
      expect(
        contrast(s.onPrimaryContainer, s.primaryContainer),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(s.onTertiaryContainer, s.tertiaryContainer),
        greaterThanOrEqualTo(4.5),
      );
      expect(contrast(s.primary, s.surface), greaterThanOrEqualTo(4.5));
    });
  }

  test('modes du lecteur lisibles (AA ≥ 4,5:1)', () {
    for (final mode in ReaderMode.values) {
      expect(
        contrast(mode.text, mode.background),
        greaterThanOrEqualTo(4.5),
        reason: mode.label,
      );
    }
  });

  test('palette de la charte respectée', () {
    final light = MurmureTheme.light().colorScheme;
    expect(light.surface, MurmureColors.ivory);
    expect(light.primary, MurmureColors.deepGreen);
    expect(light.primaryContainer, MurmureColors.paleGreen);
    expect(light.tertiaryContainer, MurmureColors.beige);
  });

  testWidgets('le choix Sombre bascule l’application', (tester) async {
    final deps = await pumpMurmure(tester);
    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sombre').first);
    await tester.pumpAndSettle();
    expect(deps.settings.themeMode, ThemeMode.dark);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });
}
