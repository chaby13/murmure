import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:murmure/domain/models/app_language.dart';
import 'package:murmure/domain/services/local_engines.dart';
import 'package:murmure/domain/text/reading_text.dart';
import 'package:murmure/presentation/reader/read_aloud_controller.dart';

class _FakePdf implements PdfEngine {
  _FakePdf(this.pages);

  final List<String> pages;

  @override
  String get label => 'PDF';
  @override
  String get ticket => 'PDF-01';
  @override
  bool get isAvailable => true;
  @override
  Future<int> pageCount(String filePath) async => pages.length;
  @override
  Future<String> extractPageText(String filePath, int pageNumber) async =>
      pages[pageNumber - 1];
}

class _FakeTts implements TtsEngine {
  final spoken = <(String, AppLanguage, double)>[];
  Completer<void>? hold;
  Object? failure;
  int stops = 0;

  @override
  String get label => 'Voix';
  @override
  String get ticket => 'TTS-01';
  @override
  bool get isAvailable => true;

  @override
  Future<void> speak(
    String text, {
    required AppLanguage language,
    double rate = 1,
  }) async {
    if (failure != null) throw failure!;
    spoken.add((text, language, rate));
    final h = hold;
    if (h != null) await h.future;
  }

  @override
  Future<void> stop() async {
    stops++;
    final h = hold;
    hold = null;
    if (h != null && !h.isCompleted) h.complete();
  }
}

ReadAloudController _controller(
  _FakeTts tts,
  List<String> pages, {
  int startPage = 1,
  void Function(int)? onPageChanged,
}) => ReadAloudController(
  tts: tts,
  pdf: _FakePdf(pages),
  filePath: 'doc.pdf',
  pageCount: pages.length,
  startPage: startPage,
  onPageChanged: onPageChanged,
);

void main() {
  group('splitSentences', () {
    test('découpe en phrases et recolle les mots coupés', () {
      expect(
        splitSentences('Bonjour à tous. Ceci est une phra-\nse coupée !\nFin?'),
        ['Bonjour à tous.', 'Ceci est une phrase coupée !', 'Fin?'],
      );
    });

    test('ignore les blocs sans lettres ni chiffres', () {
      expect(splitSentences('  \n\n — \n\nTexte.'), ['Texte.']);
    });
  });

  group('detectLanguage', () {
    test('reconnaît le français et l’anglais', () {
      expect(
        detectLanguage('Le chat est dans la maison avec les enfants.'),
        AppLanguage.fr,
      );
      expect(
        detectLanguage('The cat is in the house with the children.'),
        AppLanguage.en,
      );
    });

    test('ne tranche pas sur un texte trop court', () {
      expect(detectLanguage('Murmure'), isNull);
    });
  });

  group('ReadAloudController', () {
    test('lit toutes les phrases, page après page, puis s’arrête', () async {
      final tts = _FakeTts();
      final pages = <int>[];
      final c = _controller(tts, [
        'Le premier paragraphe est ici. Et voici la suite.',
        '',
        'La dernière page est là.',
      ], onPageChanged: pages.add);

      await c.play();

      expect(tts.spoken.map((s) => s.$1), [
        'Le premier paragraphe est ici.',
        'Et voici la suite.',
        'La dernière page est là.',
      ]);
      expect(tts.spoken.first.$2, AppLanguage.fr);
      expect(pages, [2, 3]);
      expect(c.status, ReadAloudStatus.finished);
      c.dispose();
    });

    test('choisit la voix anglaise pour un texte anglais', () async {
      final tts = _FakeTts();
      final c = _controller(tts, ['The book is on the table with the pen.']);
      await c.play();
      expect(tts.spoken.single.$2, AppLanguage.en);
      c.dispose();
    });

    test('la langue forcée et la vitesse sont transmises à la voix', () async {
      final tts = _FakeTts();
      final c = _controller(tts, ['Le chat est dans la maison avec nous.']);
      await c.setLanguage(AppLanguage.en);
      await c.setSpeed(1.5);
      await c.play();
      expect(tts.spoken.single.$2, AppLanguage.en);
      expect(tts.spoken.single.$3, 1.5);
      expect(c.isLanguageAuto, isFalse);
      c.dispose();
    });

    test('pause interrompt la lecture sur la phrase en cours', () async {
      final tts = _FakeTts()..hold = Completer();
      final c = _controller(tts, ['Une phrase. Deux phrases. Trois.']);
      unawaited(c.play());
      await pumpEventQueue();
      expect(c.status, ReadAloudStatus.playing);
      expect(c.currentSentence, 'Une phrase.');

      await c.pause();
      await pumpEventQueue();
      expect(c.status, ReadAloudStatus.paused);
      expect(tts.spoken, hasLength(1));
      expect(c.currentSentence, 'Une phrase.');
      c.dispose();
    });

    test('commence à la page affichée', () async {
      final tts = _FakeTts();
      final c = _controller(tts, ['Page un.', 'Page deux.']);
      c.followPage(2);
      await c.play();
      expect(tts.spoken.map((s) => s.$1), ['Page deux.']);
      c.dispose();
    });

    test('affiche l’erreur quand aucune voix hors ligne n’existe', () async {
      final tts = _FakeTts()
        ..failure = const TtsException('Aucune voix française hors ligne.');
      final c = _controller(tts, ['Bonjour à tous les lecteurs.']);
      await c.play();
      expect(c.error, 'Aucune voix française hors ligne.');
      expect(c.isActive, isFalse);
      c.dispose();
    });
  });
}
