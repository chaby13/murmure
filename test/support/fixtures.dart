import 'dart:io';
import 'dart:typed_data';

import 'package:murmure/domain/models/app_language.dart';
import 'package:murmure/domain/models/picked_document.dart';
import 'package:murmure/domain/services/audio_recorder.dart';
import 'package:murmure/domain/services/local_engines.dart';
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
  PickedDocument? nextAudio;
  final exported = <String, String>{};

  @override
  Future<PickedDocument?> pickPdf() async => next;

  @override
  Future<PickedDocument?> pickAudio() async => nextAudio;

  @override
  Future<bool> exportText(String fileName, String text) async {
    exported[fileName] = text;
    return true;
  }
}

/// WAV 16 kHz mono 16 bits de [seconds] secondes de silence.
File writeWav(Directory dir, String name, {int seconds = 2}) {
  const rate = 16000;
  final data = rate * 2 * seconds;
  final header = BytesBuilder()
    ..add('RIFF'.codeUnits)
    ..add(_le32(36 + data))
    ..add('WAVEfmt '.codeUnits)
    ..add(_le32(16))
    ..add([1, 0, 1, 0]) // PCM, mono
    ..add(_le32(rate))
    ..add(_le32(rate * 2))
    ..add([2, 0, 16, 0])
    ..add('data'.codeUnits)
    ..add(_le32(data));
  return File(p.join(dir.path, name))
    ..writeAsBytesSync([...header.takeBytes(), ...List.filled(data, 0)]);
}

List<int> _le32(int v) => [v & 255, v >> 8 & 255, v >> 16 & 255, v >> 24 & 255];

/// Moteur de transcription de test : renvoie un texte préparé.
class FakeAsrEngine implements AsrEngine {
  String text = 'Bonjour, ceci est un test.';
  Object? failure;
  final calls = <(String, AppLanguage?)>[];
  final vocabularies = <List<String>>[];

  @override
  String get label => 'Transcription FR/EN';
  @override
  String get ticket => 'ASR-01';
  @override
  bool get isAvailable => true;

  @override
  Future<String> transcribe(
    String audioPath, {
    AppLanguage? language,
    List<String> vocabulary = const [],
    void Function(int percent)? onProgress,
  }) async {
    calls.add((audioPath, language));
    vocabularies.add(vocabulary);
    onProgress?.call(50);
    if (failure != null) throw failure!;
    return text;
  }
}

/// Micro de test : « enregistre » un WAV préparé.
class FakeAudioRecorder implements AudioRecorderService {
  FakeAudioRecorder(this.dir);

  final Directory dir;
  bool recording = false;

  @override
  bool get isAvailable => true;

  @override
  Future<void> start() async => recording = true;

  @override
  Future<String?> stop() async {
    recording = false;
    return writeWav(dir, 'micro.wav', seconds: 3).path;
  }

  @override
  Future<void> cancel() async => recording = false;
}
