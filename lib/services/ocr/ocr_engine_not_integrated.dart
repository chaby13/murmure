import '../../domain/services/local_engines.dart';

/// Emplacement réservé à l'OCR local (ticket OCR-01).
class OcrEngineNotIntegrated implements OcrEngine {
  const OcrEngineNotIntegrated();

  @override
  String get label => 'OCR des PDF scannés';

  @override
  String get ticket => 'OCR-01';

  @override
  bool get isAvailable => false;

  @override
  Future<String> recognizePage(String filePath, int pageIndex) =>
      throw EngineNotIntegratedException(label, ticket);
}
