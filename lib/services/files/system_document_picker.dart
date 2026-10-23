import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../../domain/models/picked_document.dart';
import '../../domain/services/document_picker.dart';

/// Formats audio acceptés. Sur ordinateur, sans convertisseur embarqué,
/// seul le WAV peut être transcrit.
List<String> get supportedAudioExtensions => Platform.isWindows
    ? const ['wav']
    : const ['wav', 'mp3', 'm4a', 'aac', 'ogg', 'opus', 'flac'];

/// Sélecteur de documents du système (Fichiers sur iPhone, sélecteur de
/// documents Android). Ne demande aucune permission et n'utilise pas le
/// réseau.
class SystemDocumentPicker implements DocumentPicker {
  const SystemDocumentPicker();

  @override
  Future<PickedDocument?> pickPdf() =>
      _pick(type: FileType.custom, extensions: const ['pdf']);

  @override
  Future<PickedDocument?> pickAudio() =>
      _pick(type: FileType.custom, extensions: supportedAudioExtensions);

  @override
  Future<bool> exportText(String fileName, String text) async {
    final uri = await FilePicker.saveFile(
      dialogTitle: 'Exporter la transcription',
      fileName: fileName,
      bytes: utf8.encode(text),
      mimeType: 'text/plain',
      type: FileType.custom,
      allowedExtensions: const ['txt'],
    );
    return uri != null;
  }

  static Future<PickedDocument?> _pick({
    required FileType type,
    required List<String> extensions,
  }) async {
    final result = await FilePicker.pickFiles(
      type: type,
      allowedExtensions: extensions,
    );
    final file = result.singleOrNull;
    final path = file?.path;
    if (file == null || path == null) return null;
    return PickedDocument(name: file.name, path: path);
  }
}
