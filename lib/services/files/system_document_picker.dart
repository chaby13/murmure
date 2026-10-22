import 'package:file_picker/file_picker.dart';

import '../../domain/models/picked_document.dart';
import '../../domain/services/document_picker.dart';

/// Sélecteur de documents du système (Fichiers sur iPhone, sélecteur de
/// documents Android). Ne demande aucune permission et n'utilise pas le
/// réseau.
class SystemDocumentPicker implements DocumentPicker {
  const SystemDocumentPicker();

  @override
  Future<PickedDocument?> pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    final file = result?.files.singleOrNull;
    final path = file?.path;
    if (file == null || path == null) return null;
    return PickedDocument(name: file.name, path: path);
  }
}
