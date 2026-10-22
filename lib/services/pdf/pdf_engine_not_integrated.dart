import '../../domain/services/local_engines.dart';

/// Emplacement réservé au moteur PDF local (ticket PDF-01/PDF-02).
class PdfEngineNotIntegrated implements PdfEngine {
  const PdfEngineNotIntegrated();

  @override
  String get label => 'Lecture et extraction PDF';

  @override
  String get ticket => 'PDF-01';

  @override
  bool get isAvailable => false;

  @override
  Future<int> pageCount(String filePath) =>
      throw EngineNotIntegratedException(label, ticket);

  @override
  Future<String> extractPageText(String filePath, int pageNumber) =>
      throw EngineNotIntegratedException(label, ticket);
}
