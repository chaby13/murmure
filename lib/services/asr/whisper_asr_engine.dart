import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

import '../../domain/models/app_language.dart';
import '../../domain/services/local_engines.dart';

/// Transcription locale avec whisper.cpp. Le modèle « base » multilingue
/// (quantifié q5_1, licence MIT) est embarqué dans l'application : rien
/// n'est téléchargé, aucune donnée ne sort de l'appareil.
class WhisperAsrEngine implements AsrEngine {
  WhisperAsrEngine._(this.isAvailable);

  static const modelAsset = 'assets/models/ggml-base-q5_1.bin';

  /// Disponible seulement si la plateforme est prise en charge et si le
  /// modèle a bien été inclus dans cette version de l'application.
  static Future<WhisperAsrEngine> load() async {
    final supported =
        Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isWindows ||
        Platform.isMacOS;
    if (!supported) return WhisperAsrEngine._(false);
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return WhisperAsrEngine._(manifest.listAssets().contains(modelAsset));
  }

  @override
  String get label => 'Transcription FR/EN';

  @override
  String get ticket => 'ASR-01';

  @override
  final bool isAvailable;

  String? _modelPath;

  @override
  Future<String> transcribe(
    String audioPath, {
    AppLanguage? language,
    void Function(int percent)? onProgress,
  }) async {
    if (!isAvailable) throw EngineNotIntegratedException(label, ticket);
    final modelPath = _modelPath ??= await _installModel();
    final converted = File('$audioPath.wav');
    try {
      final response = await const Whisper(model: WhisperModel.base).transcribe(
        transcribeRequest: TranscribeRequest(
          audio: audioPath,
          language: language?.code ?? 'auto',
          threads: max(1, min(4, Platform.numberOfProcessors)),
          isNoTimestamps: true,
          // Évite qu'une phrase mal reconnue se répète sur tout l'audio.
          maxContext: 0,
          suppressNonSpeechTokens: true,
        ),
        modelPath: modelPath,
        onProgress: onProgress,
      );
      return response.text.trim();
    } catch (_) {
      throw const AsrException(
        'Ce fichier audio n’a pas pu être transcrit. Essayez un '
        'enregistrement WAV, M4A ou MP3 non protégé.',
      );
    } finally {
      // Copie convertie en WAV 16 kHz laissée par le moteur.
      if (await converted.exists()) await converted.delete();
    }
  }

  /// Copie le modèle depuis l'application vers un fichier que whisper.cpp
  /// peut ouvrir. Fait une seule fois.
  static Future<String> _installModel() async {
    final dir = await getApplicationSupportDirectory();
    final target = File(p.join(dir.path, 'models', p.basename(modelAsset)));
    final data = await rootBundle.load(modelAsset);
    if (await target.exists() && await target.length() == data.lengthInBytes) {
      return target.path;
    }
    await target.parent.create(recursive: true);
    final partial = File('${target.path}.part');
    await partial.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
    await partial.rename(target.path);
    return target.path;
  }
}
