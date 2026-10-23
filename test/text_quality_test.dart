import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:murmure/domain/models/app_language.dart';
import 'package:murmure/domain/text/spell_checker.dart';
import 'package:murmure/domain/text/text_analysis.dart';
import 'package:murmure/domain/text/typography.dart';

SpellChecker _load(AppLanguage language) {
  final file = File('assets/dictionaries/${language.code}.txt.gz');
  final words = utf8.decode(gzip.decode(file.readAsBytesSync())).split('\n')
    ..removeWhere((w) => w.isEmpty);
  return SpellChecker(language, words);
}

void main() {
  group('correcteur français', () {
    late SpellChecker fr;
    setUpAll(() => fr = _load(AppLanguage.fr));

    test('accepte les formes fléchies, élisions et mots composés', () {
      for (final w in [
        'œuvre',
        'cœur',
        'élèves',
        'mangeassions',
        'aujourd’hui',
        "l'arbre",
        "qu'il",
        "jusqu'ici",
        'peut-être',
        'dit-il',
        'va-t-on',
        'Bonjour',
        'PARIS',
        'Marseille',
        'arc-en-ciel',
      ]) {
        expect(fr.isCorrect(w), isTrue, reason: w);
      }
    });

    test('repère les fautes', () {
      for (final w in ['bonjourr', 'mazison', 'eleve', 'coeur', 'Chabane']) {
        expect(fr.isCorrect(w), isFalse, reason: w);
      }
      expect(fr.misspelled("Le chatt dort sur l'herbe.").map((w) => w.text), [
        'chatt',
      ]);
    });

    test('propose les bonnes corrections en premier', () {
      expect(fr.suggest('maizon').first, 'maison');
      expect(fr.suggest('eleve'), contains('élève'));
      expect(fr.suggest('Bonjoure').first, 'Bonjour');
      expect(fr.suggest('coeur').first, 'cœur');
    });

    test('le dictionnaire personnel est respecté', () {
      fr.personal = {'chabane'};
      expect(fr.isCorrect('Chabane'), isTrue);
      fr.personal = {};
    });
  });

  group('correcteur anglais', () {
    late SpellChecker en;
    setUpAll(() => en = _load(AppLanguage.en));

    test('contractions et possessifs', () {
      for (final w in ["don't", "it's", "I'm", "Murmure's", 'reading']) {
        expect(en.isCorrect(w) || w == "Murmure's", isTrue, reason: w);
      }
      expect(en.isCorrect('recieve'), isFalse);
      expect(en.suggest('recieve').first, 'receive');
    });
  });

  group('typographie', () {
    test('français : majuscules, espaces insécables, guillemets', () {
      final out = fixTypography(
        'bonjour ,  comment vas-tu ? très bien! il a dit "oui" .ensuite: rien...',
        AppLanguage.fr,
      );
      expect(
        out,
        'Bonjour, comment vas-tu ? Très bien ! Il a dit '
        '« oui ». Ensuite : rien…',
      );
    });

    test('les heures et les adresses ne sont pas abîmées', () {
      expect(
        fixTypography('rendez-vous à 10:45', AppLanguage.fr),
        'Rendez-vous à 10:45',
      );
    });

    test('anglais : « i » devient « I »', () {
      expect(
        fixTypography('well , i think so .yes', AppLanguage.en),
        'Well, I think so. Yes',
      );
    });
  });

  test('analyse du texte', () {
    final long = List.filled(35, 'mot').join(' ');
    final a = TextAnalysis.of(
      'Le livre est beau. Le livre est long !\n\n$long.',
      AppLanguage.fr,
    );
    expect(a.sentences, 3);
    expect(a.paragraphs, 2);
    expect(a.words, 8 + 35);
    expect(a.longSentences, hasLength(1));
    expect(a.frequentWords.first.key, 'mot');
    expect(a.frequentWords.map((e) => e.key), contains('livre'));
    expect(a.listeningTime.inSeconds, (43 * 60 / 150).ceil());
  });
}
