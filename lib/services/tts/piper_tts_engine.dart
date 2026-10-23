import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../../domain/models/app_language.dart';
import '../../domain/services/local_engines.dart';

/// Une voix naturelle embarquée dans l'application.
class _EmbeddedVoice {
  const _EmbeddedVoice(this.id, this.language, this.voice);

  /// Nom des fichiers dans assets/voices/.
  final String id;
  final AppLanguage language;
  final TtsVoice voice;
}

const _embedded = [
  _EmbeddedVoice(
    'fr_FR-siwis-medium',
    AppLanguage.fr,
    TtsVoice(name: 'Siwis (voix naturelle)', locale: 'fr-FR', gender: 'female'),
  ),
  _EmbeddedVoice(
    'en_GB-alba-medium',
    AppLanguage.en,
    TtsVoice(name: 'Alba (voix naturelle)', locale: 'en-GB', gender: 'female'),
  ),
];

const _assetDir = 'assets/voices';

/// Voix naturelles Piper (CC-BY 4.0) calculées sur l'appareil avec
/// sherpa-onnx, puis jouées comme un son. Aucune donnée ne sort de
/// l'appareil.
class PiperTtsEngine implements TtsEngine {
  PiperTtsEngine._(this._voices);

  /// Ne garde que les voix réellement incluses dans cette version.
  static Future<PiperTtsEngine?> load() async {
    if (!(Platform.isAndroid || Platform.isIOS || Platform.isWindows)) {
      return null;
    }
    final assets = (await AssetManifest.loadFromAssetBundle(rootBundle))
        .listAssets()
        .toSet();
    final voices = [
      for (final v in _embedded)
        if (assets.contains('$_assetDir/${v.id}.onnx')) v,
    ];
    if (voices.isEmpty || !assets.contains('$_assetDir/espeak-ng-data.zip')) {
      return null;
    }
    return PiperTtsEngine._(voices);
  }

  final List<_EmbeddedVoice> _voices;
  final _player = AudioPlayer();
  final Map<String, Future<String>> _prepared = {};
  _Worker? _worker;
  Completer<void>? _playing;
  int _clip = 0;

  @override
  String get label => 'Voix naturelles embarquées (Piper)';

  @override
  String get ticket => 'TTS-01';

  @override
  bool get isAvailable => true;

  /// Vrai si [name] désigne une voix embarquée.
  bool owns(String? name) => _voices.any((v) => v.voice.name == name);

  @override
  Future<List<TtsVoice>> voices(AppLanguage language) async => [
    for (final v in _voices)
      if (v.language == language) v.voice,
  ];

  /// Calcule à l'avance le son de [text] pour enchaîner sans blanc.
  @override
  void prepare(
    String text, {
    required AppLanguage language,
    double rate = 1,
    String? voiceName,
  }) {
    final voice = _pick(language, voiceName);
    if (voice == null) return;
    _render(voice, text, rate).ignore();
  }

  @override
  Future<void> speak(
    String text, {
    required AppLanguage language,
    double rate = 1,
    String? voiceName,
  }) async {
    final voice = _pick(language, voiceName);
    if (voice == null) {
      throw const TtsException('Aucune voix naturelle pour cette langue.');
    }
    final String path;
    try {
      path = await _render(voice, text, rate);
    } catch (e) {
      throw TtsException('La voix naturelle n’a pas pu parler.\nDétail : $e');
    }
    _prepared.remove(_key(voice, text, rate));
    final done = _playing = Completer<void>();
    final sub = _player.onPlayerComplete.listen((_) {
      if (!done.isCompleted) done.complete();
    });
    try {
      await _player.play(DeviceFileSource(path));
      await done.future;
    } finally {
      await sub.cancel();
      File(path).delete().ignore();
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    final playing = _playing;
    if (playing != null && !playing.isCompleted) playing.complete();
  }

  _EmbeddedVoice? _pick(AppLanguage language, String? name) {
    final candidates = [
      for (final v in _voices)
        if (v.language == language) v,
    ];
    if (candidates.isEmpty) return null;
    return candidates.firstWhere(
      (v) => v.voice.name == name,
      orElse: () => candidates.first,
    );
  }

  String _key(_EmbeddedVoice voice, String text, double rate) =>
      '${voice.id}|$rate|$text';

  Future<String> _render(_EmbeddedVoice voice, String text, double rate) {
    final key = _key(voice, text, rate);
    return _prepared[key] ??= () async {
      final worker = _worker ??= await _Worker.start(await _install());
      final dir = await getTemporaryDirectory();
      final out = p.join(dir.path, 'murmure-voix-${_clip++}.wav');
      await worker.render(voice.id, text, rate, out);
      return out;
    }();
  }

  /// Copie les voix hors de l'application (une seule fois) pour que le
  /// moteur puisse les ouvrir.
  Future<String> _install() async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, 'voix'));
    final marker = File(p.join(dir.path, 'installe-v1'));
    if (await marker.exists()) return dir.path;
    await dir.create(recursive: true);
    for (final v in _voices) {
      for (final suffix in ['.onnx', '.tokens.txt']) {
        final data = await rootBundle.load('$_assetDir/${v.id}$suffix');
        await File(p.join(dir.path, '${v.id}$suffix')).writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          flush: true,
        );
      }
    }
    final zip = await rootBundle.load('$_assetDir/espeak-ng-data.zip');
    final archive = ZipDecoder().decodeBytes(
      zip.buffer.asUint8List(zip.offsetInBytes, zip.lengthInBytes),
    );
    await extractArchiveToDisk(archive, dir.path);
    await marker.writeAsString('ok');
    return dir.path;
  }
}

/// Isolat qui garde les voix chargées et calcule les sons sans figer
/// l'interface.
class _Worker {
  _Worker(this._send, this._replies);

  final SendPort _send;
  final Stream<dynamic> _replies;
  int _next = 0;

  static Future<_Worker> start(String voicesDir) async {
    final receive = ReceivePort();
    await Isolate.spawn(_main, [receive.sendPort, voicesDir]);
    final replies = receive.asBroadcastStream();
    final send = await replies.first as SendPort;
    return _Worker(send, replies);
  }

  Future<void> render(String id, String text, double rate, String out) async {
    final ticket = _next++;
    final reply = _replies.firstWhere((m) => m is List && m[0] == ticket);
    _send.send([ticket, id, text, rate, out]);
    final result = await reply as List;
    if (result[1] != null) throw Exception(result[1]);
  }

  static void _main(List<Object> args) {
    final reply = args[0] as SendPort;
    final dir = args[1] as String;
    final requests = ReceivePort();
    reply.send(requests.sendPort);
    sherpa.initBindings();
    final loaded = <String, sherpa.OfflineTts>{};
    requests.listen((message) {
      final m = message as List;
      final ticket = m[0] as int;
      try {
        final id = m[1] as String;
        final tts = loaded[id] ??= sherpa.OfflineTts(
          sherpa.OfflineTtsConfig(
            model: sherpa.OfflineTtsModelConfig(
              vits: sherpa.OfflineTtsVitsModelConfig(
                model: p.join(dir, '$id.onnx'),
                tokens: p.join(dir, '$id.tokens.txt'),
                dataDir: p.join(dir, 'espeak-ng-data'),
              ),
              numThreads: Platform.numberOfProcessors >= 4 ? 2 : 1,
              debug: false,
            ),
          ),
        );
        final audio = tts.generate(text: m[2] as String, speed: m[3] as double);
        sherpa.writeWave(
          filename: m[4] as String,
          samples: audio.samples,
          sampleRate: audio.sampleRate,
        );
        reply.send([ticket, null]);
      } catch (e) {
        reply.send([ticket, '$e']);
      }
    });
  }
}
