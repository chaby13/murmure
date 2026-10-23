import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmure/core/settings/settings_controller.dart';
import 'package:murmure/core/theme/murmure_colors.dart';
import 'package:murmure/domain/models/app_language.dart';
import 'package:murmure/domain/models/read_aloud_preferences.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('murmure_settings_'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('voix, vitesse et apparence sont retrouvées au lancement', () async {
    final file = File(p.join(dir.path, 'reglages.json'));
    final settings = await SettingsController.load(file);
    expect(settings.readAloud.speed, SettingsController.defaultReadSpeed);

    settings
      ..themeMode = ThemeMode.dark
      ..readerMode = ReaderMode.sepia
      ..readAloud = const ReadAloudPreferences(
        speed: 0.8,
        voices: {AppLanguage.fr: 'Microsoft Paul'},
      );
    await settings.saved;

    final again = await SettingsController.load(file);
    expect(again.themeMode, ThemeMode.dark);
    expect(again.readerMode, ReaderMode.sepia);
    expect(again.readAloud.speed, 0.8);
    expect(again.readAloud.voices, {AppLanguage.fr: 'Microsoft Paul'});
  });

  test('le dictionnaire personnel est retrouvé, sans doublon', () async {
    final file = File(p.join(dir.path, 'reglages.json'));
    final settings = await SettingsController.load(file);
    settings
      ..addPersonalWord('Murmure')
      ..addPersonalWord(' chabane ')
      ..addPersonalWord('murmure');
    expect(settings.personalWords, ['chabane', 'Murmure']);
    settings.removePersonalWord('chabane');
    await settings.saved;
    final again = await SettingsController.load(file);
    expect(again.personalWords, ['Murmure']);
  });

  test('un fichier abîmé redonne les réglages par défaut', () async {
    final file = File(p.join(dir.path, 'reglages.json'))
      ..writeAsStringSync('{pas du json');
    final settings = await SettingsController.load(file);
    expect(settings.themeMode, ThemeMode.system);
  });
}
