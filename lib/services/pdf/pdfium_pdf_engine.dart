import 'package:pdfrx_engine/pdfrx_engine.dart';

import '../../domain/services/local_engines.dart';

/// Moteur PDF local fondé sur PDFium (via pdfrx, licences MIT et BSD).
/// Il ne lit que des fichiers locaux : l'ouverture par URL de pdfrx n'est
/// jamais utilisée.
class PdfiumPdfEngine implements PdfEngine {
  const PdfiumPdfEngine();

  @override
  String get label => 'Lecture et extraction PDF';

  @override
  String get ticket => 'PDF-01';

  @override
  bool get isAvailable => true;

  @override
  Future<int> pageCount(String filePath) =>
      _withDocument(filePath, (doc) async => doc.pages.length);

  @override
  Future<String> extractPageText(String filePath, int pageNumber) =>
      _withDocument(filePath, (doc) async {
        if (pageNumber < 1 || pageNumber > doc.pages.length) {
          throw RangeError.range(pageNumber, 1, doc.pages.length, 'pageNumber');
        }
        final text = await doc.pages[pageNumber - 1].loadText();
        return text?.fullText.trim() ?? '';
      });

  static Future<T> _withDocument<T>(
    String filePath,
    Future<T> Function(PdfDocument doc) action,
  ) async {
    final PdfDocument doc;
    try {
      doc = await PdfDocument.openFile(filePath);
    } on PdfPasswordException {
      throw const PdfOpenException(
        'Ce PDF est protégé par un mot de passe. Ce n’est pas encore pris en charge.',
      );
    } catch (_) {
      throw const PdfOpenException('Ce PDF est endommagé ou illisible.');
    }
    try {
      return await action(doc);
    } finally {
      await doc.dispose();
    }
  }
}
