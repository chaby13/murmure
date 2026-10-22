import '../models/picked_document.dart';

/// Ouvre le sélecteur de fichiers du système.
abstract interface class DocumentPicker {
  /// Renvoie null si l'utilisateur annule.
  Future<PickedDocument?> pickPdf();
}
