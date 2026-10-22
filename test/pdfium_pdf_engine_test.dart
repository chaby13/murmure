import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:murmure/domain/services/local_engines.dart';
import 'package:murmure/services/pdf/pdfium_pdf_engine.dart';
import 'package:pdfrx_engine/pdfrx_engine.dart';

void main() {
  setUpAll(() => pdfrxInitialize());

  const engine = PdfiumPdfEngine();
  const fixture = 'test/fixtures/deux_pages.pdf';

  test('compte les pages d’un vrai PDF', () async {
    expect(await engine.pageCount(fixture), greaterThanOrEqualTo(1));
  });

  test('extrait le texte, accents compris', () async {
    final pages = await engine.pageCount(fixture);
    final all = StringBuffer();
    for (var page = 1; page <= pages; page++) {
      all.writeln(await engine.extractPageText(fixture, page));
    }
    expect(
      all.toString(),
      contains('Learning a new language requires patience'),
    );
    expect(all.toString(), contains('Apprendre une nouvelle langue ouvre'));
  });

  test('un fichier endommagé lève une erreur lisible', () async {
    final dir = Directory.systemTemp.createTempSync('murmure_pdf_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final broken = File('${dir.path}/casse.pdf')
      ..writeAsStringSync('%PDF-1.4\nceci n’est pas un PDF complet');
    expect(
      () => engine.pageCount(broken.path),
      throwsA(isA<PdfOpenException>()),
    );
  });
}
