import 'dart:io';

import 'package:murmure/domain/models/picked_document.dart';
import 'package:murmure/domain/services/document_picker.dart';
import 'package:path/path.dart' as p;

/// Plus petit PDF valide d'une page.
const minimalPdf =
    '%PDF-1.4\n'
    '1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj\n'
    '2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj\n'
    '3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 200 200] >> endobj\n'
    'trailer << /Root 1 0 R >>\n%%EOF\n';

File writeFile(Directory dir, String name, String content) =>
    File(p.join(dir.path, name))..writeAsStringSync(content);

/// Sélecteur qui renvoie un fichier préparé par le test.
class FakeDocumentPicker implements DocumentPicker {
  PickedDocument? next;

  @override
  Future<PickedDocument?> pickPdf() async => next;
}
