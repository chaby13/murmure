import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:murmure/services/asr/wav_normalizer.dart';
import 'package:path/path.dart' as p;

/// WAV de [seconds] s d'une sinusoïde à 440 Hz, au format demandé.
File _wav(
  Directory dir, {
  required int rate,
  required int channels,
  required int bits,
  bool float = false,
  bool extensible = false,
  double seconds = 1,
}) {
  final frames = (rate * seconds).round();
  final bytesPer = bits ~/ 8;
  final data = ByteData(frames * channels * bytesPer);
  for (var f = 0; f < frames; f++) {
    final v = 0.5 * sin(2 * pi * 440 * f / rate);
    for (var c = 0; c < channels; c++) {
      final o = (f * channels + c) * bytesPer;
      if (float) {
        data.setFloat32(o, v, Endian.little);
      } else if (bits == 16) {
        data.setInt16(o, (v * 32767).round(), Endian.little);
      } else if (bits == 24) {
        final s = (v * 8388607).round();
        data.setUint8(o, s & 255);
        data.setUint8(o + 1, s >> 8 & 255);
        data.setUint8(o + 2, s >> 16 & 255);
      }
    }
  }
  final fmtSize = extensible ? 40 : 16;
  final h = ByteData(12 + 8 + fmtSize + 8);
  void tag(int at, String s) {
    for (var i = 0; i < 4; i++) {
      h.setUint8(at + i, s.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  h.setUint32(4, h.lengthInBytes - 8 + data.lengthInBytes, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  h.setUint32(16, fmtSize, Endian.little);
  final code = float ? 3 : 1;
  h.setUint16(20, extensible ? 0xfffe : code, Endian.little);
  h.setUint16(22, channels, Endian.little);
  h.setUint32(24, rate, Endian.little);
  h.setUint32(28, rate * channels * bytesPer, Endian.little);
  h.setUint16(32, channels * bytesPer, Endian.little);
  h.setUint16(34, bits, Endian.little);
  if (extensible) h.setUint16(20 + 24, code, Endian.little);
  tag(20 + fmtSize, 'data');
  h.setUint32(24 + fmtSize, data.lengthInBytes, Endian.little);
  return File(p.join(dir.path, 'in-$rate-$channels-$bits.wav'))
    ..writeAsBytesSync([
      ...h.buffer.asUint8List(),
      ...data.buffer.asUint8List(),
    ]);
}

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('murmure_wav_'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<ByteData> convert(File input) async {
    final out = await normalizeWav(input, File(p.join(dir.path, 'out.wav')));
    expect(out, isNotNull);
    return ByteData.sublistView(out!.readAsBytesSync());
  }

  void expectWhisperFormat(ByteData d, {required int frames}) {
    expect(String.fromCharCodes(d.buffer.asUint8List(0, 4)), 'RIFF');
    expect(d.getUint16(20, Endian.little), 1); // PCM
    expect(d.getUint16(22, Endian.little), 1); // mono
    expect(d.getUint32(24, Endian.little), 16000);
    expect(d.getUint16(34, Endian.little), 16);
    expect(d.getUint32(40, Endian.little), frames * 2);
    expect(d.lengthInBytes, 44 + frames * 2);
  }

  test('48 kHz stéréo 16 bits → 16 kHz mono, signal conservé', () async {
    final d = await convert(_wav(dir, rate: 48000, channels: 2, bits: 16));
    expectWhisperFormat(d, frames: 16000);
    var peak = 0;
    for (var i = 44; i < d.lengthInBytes; i += 2) {
      peak = max(peak, d.getInt16(i, Endian.little).abs());
    }
    expect(peak, inInclusiveRange(15000, 17000)); // amplitude 0,5
  });

  test('44,1 kHz flottant (format étendu) est accepté', () async {
    final d = await convert(
      _wav(
        dir,
        rate: 44100,
        channels: 1,
        bits: 32,
        float: true,
        extensible: true,
      ),
    );
    expectWhisperFormat(d, frames: 16000);
  });

  test('24 bits et déjà 16 kHz', () async {
    expectWhisperFormat(
      await convert(_wav(dir, rate: 16000, channels: 1, bits: 24)),
      frames: 16000,
    );
  });

  test('un fichier qui n’est pas un WAV est laissé au moteur', () async {
    final mp3 = File(p.join(dir.path, 'a.mp3'))
      ..writeAsBytesSync(List.filled(100, 7));
    expect(await normalizeWav(mp3, File(p.join(dir.path, 'o.wav'))), isNull);
  });
}
