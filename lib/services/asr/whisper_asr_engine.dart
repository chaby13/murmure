import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

import '../../domain/models/app_language.dart';
import '../../domain/services/local_engines.dart';
import 'wav_normalizer.dart';

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
    final String modelPath;
    try {
      modelPath = _modelPath ??= await _installModel();
    } catch (e) {
      throw AsrException(
        'Le moteur de transcription n’a pas pu être préparé.\nDétail : $e',
      );
    }
    // Un WAV est remis au format exact attendu (16 kHz mono) par Murmure
    // lui-même ; les autres formats passent par le convertisseur du moteur.
    final normalized = File(
      p.join(p.dirname(modelPath), 'transcription-en-cours.wav'),
    );
    final converted = File('$audioPath.wav');
    try {
      final input =
          await normalizeWav(File(audioPath), normalized) ?? File(audioPath);
      final response = await const Whisper(model: WhisperModel.base).transcribe(
        transcribeRequest: TranscribeRequest(
          audio: input.path,
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
    } catch (e) {
      throw AsrException(
        'Ce fichier audio n’a pas pu être transcrit.\nDétail : $e',
      );
    } finally {
      // Copies converties laissées par Murmure et par le moteur.
      for (final f in [normalized, converted, File('${normalized.path}.wav')]) {
        if (await f.exists()) await f.delete();
      }
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
