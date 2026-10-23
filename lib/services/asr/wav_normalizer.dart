import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Format attendu par whisper.cpp : WAV PCM 16 bits, mono, 16 kHz.
const whisperSampleRate = 16000;

/// Convertit un WAV quelconque (PCM 8/16/24/32 bits ou flottant 32 bits,
/// mono ou multicanal, toute fréquence) en WAV 16 kHz mono 16 bits, sans
/// outil externe. Renvoie null si [input] n'est pas un WAV lisible.
///
/// Sur Windows, le micro enregistre souvent en 44,1 ou 48 kHz quel que soit
/// le réglage demandé, et aucun convertisseur n'est embarqué.
Future<File?> normalizeWav(File input, File output) async {
  final raf = await input.open();
  try {
    final format = await _readFormat(raf);
    if (format == null) return null;

    final frameBytes = format.channels * format.bytesPerSample;
    final totalFrames = format.dataLength ~/ frameBytes;
    final ratio = format.sampleRate / whisperSampleRate;
    final outFrames = (totalFrames / ratio).floor();

    final sink = output.openWrite();
    sink.add(_header(outFrames * 2));

    // Lecture par blocs : un long enregistrement ne tient pas en mémoire.
    const blockFrames = 1 << 16;
    var blockStart = 0;
    var mono = Float32List(0);
    var outIndex = 0;
    final out = BytesBuilder(copy: false);

    Future<void> loadBlock(int start) async {
      final frames = min(blockFrames + 1, totalFrames - start);
      await raf.setPosition(format.dataOffset + start * frameBytes);
      final bytes = await raf.read(frames * frameBytes);
      final data = ByteData.sublistView(bytes);
      final usable = bytes.length ~/ frameBytes;
      mono = Float32List(usable);
      for (var f = 0; f < usable; f++) {
        var sum = 0.0;
        for (var c = 0; c < format.channels; c++) {
          sum += format.sample(
            data,
            f * frameBytes + c * format.bytesPerSample,
          );
        }
        mono[f] = sum / format.channels;
      }
      blockStart = start;
    }

    if (totalFrames > 0) await loadBlock(0);
    while (outIndex < outFrames) {
      final position = outIndex * ratio;
      final i = position.floor();
      if (i + 1 >= blockStart + mono.length && i + 1 < totalFrames) {
        await loadBlock(i);
      }
      final local = i - blockStart;
      final a = mono[min(local, mono.length - 1)];
      final b = mono[min(local + 1, mono.length - 1)];
      final value = a + (b - a) * (position - i);
      final s = (value * 32767).round().clamp(-32768, 32767);
      out.addByte(s & 0xff);
      out.addByte((s >> 8) & 0xff);
      outIndex++;
      if (out.length >= 1 << 20) sink.add(out.takeBytes());
    }
    sink.add(out.takeBytes());
    await sink.close();
    return output;
  } finally {
    await raf.close();
  }
}

class _WavFormat {
  _WavFormat({
    required this.audioFormat,
    required this.channels,
    required this.sampleRate,
    required this.bitsPerSample,
    required this.dataOffset,
    required this.dataLength,
  });

  final int audioFormat; // 1 = PCM entier, 3 = flottant
  final int channels;
  final int sampleRate;
  final int bitsPerSample;
  final int dataOffset;
  final int dataLength;

  int get bytesPerSample => bitsPerSample ~/ 8;

  /// Échantillon ramené entre -1 et 1.
  double sample(ByteData d, int o) {
    if (audioFormat == 3) return d.getFloat32(o, Endian.little);
    return switch (bitsPerSample) {
      8 => (d.getUint8(o) - 128) / 128,
      16 => d.getInt16(o, Endian.little) / 32768,
      24 =>
        ((d.getUint8(o) | d.getUint8(o + 1) << 8 | d.getInt8(o + 2) << 16) /
            8388608),
      _ => d.getInt32(o, Endian.little) / 2147483648,
    };
  }
}

Future<_WavFormat?> _readFormat(RandomAccessFile raf) async {
  final length = await raf.length();
  final riff = await raf.read(12);
  if (riff.length < 12 ||
      String.fromCharCodes(riff.sublist(0, 4)) != 'RIFF' ||
      String.fromCharCodes(riff.sublist(8, 12)) != 'WAVE') {
    return null;
  }
  int? audioFormat, channels, sampleRate, bits;
  var offset = 12;
  while (offset + 8 <= length) {
    await raf.setPosition(offset);
    final head = ByteData.sublistView(await raf.read(8));
    final id = String.fromCharCodes(List.generate(4, (i) => head.getUint8(i)));
    final size = head.getUint32(4, Endian.little);
    final body = offset + 8;
    if (id == 'fmt ') {
      final fmt = ByteData.sublistView(await raf.read(min(size, 40)));
      audioFormat = fmt.getUint16(0, Endian.little);
      channels = fmt.getUint16(2, Endian.little);
      sampleRate = fmt.getUint32(4, Endian.little);
      bits = fmt.getUint16(14, Endian.little);
      // WAVE_FORMAT_EXTENSIBLE : le vrai format est dans le sous-type.
      if (audioFormat == 0xfffe && fmt.lengthInBytes >= 26) {
        audioFormat = fmt.getUint16(24, Endian.little);
      }
    } else if (id == 'data') {
      if (audioFormat == null ||
          channels == null ||
          channels == 0 ||
          sampleRate == null ||
          sampleRate == 0 ||
          bits == null) {
        return null;
      }
      final supported =
          (audioFormat == 1 && const [8, 16, 24, 32].contains(bits)) ||
          (audioFormat == 3 && bits == 32);
      if (!supported) return null;
      // Certains enregistreurs laissent la taille à 0 ou trop grande.
      final available = length - body;
      final dataLength = size == 0 || size > available ? available : size;
      return _WavFormat(
        audioFormat: audioFormat,
        channels: channels,
        sampleRate: sampleRate,
        bitsPerSample: bits,
        dataOffset: body,
        dataLength: dataLength,
      );
    }
    offset = body + size + (size & 1);
  }
  return null;
}

Uint8List _header(int dataBytes) {
  final h = ByteData(44);
  void tag(int at, String s) {
    for (var i = 0; i < 4; i++) {
      h.setUint8(at + i, s.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  h.setUint32(4, 36 + dataBytes, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  h.setUint32(16, 16, Endian.little);
  h.setUint16(20, 1, Endian.little);
  h.setUint16(22, 1, Endian.little);
  h.setUint32(24, whisperSampleRate, Endian.little);
  h.setUint32(28, whisperSampleRate * 2, Endian.little);
  h.setUint16(32, 2, Endian.little);
  h.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  h.setUint32(40, dataBytes, Endian.little);
  return h.buffer.asUint8List();
}
