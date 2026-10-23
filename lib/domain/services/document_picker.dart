import '../models/picked_document.dart';

/// Ouvre le sélecteur de fichiers du système.
abstract interface class DocumentPicker {
  /// Renvoie null si l'utilisateur annule.
  Future<PickedDocument?> pickPdf();

  /// Fichier audio à transcrire. Renvoie null si l'utilisateur annule.
  Future<PickedDocument?> pickAudio();

  /// Enregistre [text] dans un fichier .txt choisi par l'utilisateur.
  /// Renvoie false si l'utilisateur annule.
  Future<bool> exportText(String fileName, String text);
}
