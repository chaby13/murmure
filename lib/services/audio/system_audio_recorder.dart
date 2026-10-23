import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../domain/services/audio_recorder.dart';

/// Micro de l'appareil via le paquet `record`. Le son reste dans un fichier
/// temporaire local jusqu'à son ajout à la bibliothèque.
class SystemAudioRecorder implements AudioRecorderService {
  final _recorder = AudioRecorder();

  @override
  bool get isAvailable => true;

  @override
  Future<void> start() async {
    if (!await _recorder.hasPermission()) {
      throw const RecorderException(
        'Murmure n’a pas accès au micro. Autorisez-le dans les réglages de '
        'l’appareil, puis réessayez.',
      );
    }
    final dir = await getTemporaryDirectory();
    final path = p.join(
      dir.path,
      'enregistrement-${DateTime.now().millisecondsSinceEpoch}.wav',
    );
    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );
    } catch (_) {
      throw const RecorderException(
        'Le micro n’a pas pu démarrer. Vérifiez qu’aucune autre application '
        'ne l’utilise.',
      );
    }
  }

  @override
  Future<String?> stop() async {
    final path = await _recorder.stop();
    if (path == null || !await File(path).exists()) return null;
    return path;
  }

  @override
  Future<void> cancel() => _recorder.cancel();
}
