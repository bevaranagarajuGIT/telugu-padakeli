import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';

class PronunciationClip {
  const PronunciationClip({required this.text, required this.asset});

  final String text;
  final String asset;
}

class PronunciationPack {
  const PronunciationPack._(this.clips, this.pendingCount);
  const PronunciationPack.empty() : clips = const {}, pendingCount = 0;

  final Map<String, PronunciationClip> clips;
  final int pendingCount;

  static PronunciationPack parse(String source) {
    final data = jsonDecode(source);
    if (data is! Map<String, dynamic> ||
        data['version'] != 1 ||
        data['language'] != 'te-IN' ||
        data['clips'] is! List) {
      throw const FormatException('Invalid Telugu pronunciation pack.');
    }
    final approved = <String, PronunciationClip>{};
    final texts = <String>{};
    final ids = <String>{};
    var pending = 0;
    for (final entry in data['clips'] as List) {
      if (entry is! Map<String, dynamic>) {
        throw const FormatException('Invalid pronunciation entry.');
      }
      final id = entry['id'];
      final text = entry['text'];
      final status = entry['status'];
      if (id is! String ||
          !RegExp(r'^[a-z][a-z0-9-]*$').hasMatch(id) ||
          !ids.add(id) ||
          text is! String ||
          text.trim().isEmpty ||
          text != text.trim() ||
          !texts.add(text) ||
          !{'pending-recording', 'reviewed'}.contains(status) ||
          entry['asset'] != 'assets/audio/pronunciation/$id.wav') {
        throw const FormatException('Invalid pronunciation entry metadata.');
      }
      if (status == 'pending-recording') {
        pending++;
        continue;
      }
      if (entry['nativeSpeakerReviewed'] != true ||
          entry['distributionPermission'] != true ||
          entry['license'] is! String ||
          (entry['license'] as String).trim().isEmpty) {
        throw FormatException('Pronunciation approval is incomplete: $id.');
      }
      approved[text] = PronunciationClip(text: text, asset: entry['asset']);
    }
    return PronunciationPack._(Map.unmodifiable(approved), pending);
  }

  static Future<PronunciationPack> load(AssetBundle bundle) async {
    final pack = parse(
      await bundle.loadString('assets/data/pronunciation_pack.json'),
    );
    for (final clip in pack.clips.values) {
      final bytes = await bundle.load(clip.asset);
      if (!_isPcmWav(bytes)) {
        throw FormatException('Invalid bundled WAV recording: ${clip.asset}.');
      }
    }
    return pack;
  }

  static bool _isPcmWav(ByteData bytes) {
    String tag(int offset) => ascii.decode(
      bytes.buffer.asUint8List(bytes.offsetInBytes + offset, 4),
      allowInvalid: true,
    );
    if (bytes.lengthInBytes < 44 ||
        tag(0) != 'RIFF' ||
        tag(8) != 'WAVE' ||
        bytes.getUint32(4, Endian.little) + 8 != bytes.lengthInBytes) {
      return false;
    }
    var validFormat = false;
    var hasSamples = false;
    var sampleBytes = 0;
    var frameSize = 0;
    var offset = 12;
    while (offset + 8 <= bytes.lengthInBytes) {
      final size = bytes.getUint32(offset + 4, Endian.little);
      final start = offset + 8;
      if (start + size > bytes.lengthInBytes) return false;
      if (tag(offset) == 'fmt ') {
        if (size < 16) return false;
        final channels = bytes.getUint16(start + 2, Endian.little);
        final rate = bytes.getUint32(start + 4, Endian.little);
        final alignment = bytes.getUint16(start + 12, Endian.little);
        frameSize = alignment;
        validFormat =
            bytes.getUint16(start, Endian.little) == 1 &&
            (channels == 1 || channels == 2) &&
            rate >= 16000 &&
            rate <= 48000 &&
            bytes.getUint16(start + 14, Endian.little) == 16 &&
            alignment == channels * 2 &&
            bytes.getUint32(start + 8, Endian.little) == rate * alignment;
      } else if (tag(offset) == 'data') {
        hasSamples = size > 0 && size.isEven;
        sampleBytes = size;
      }
      offset = start + size + size % 2;
    }
    return validFormat &&
        hasSamples &&
        sampleBytes % frameSize == 0 &&
        offset == bytes.lengthInBytes;
  }
}
