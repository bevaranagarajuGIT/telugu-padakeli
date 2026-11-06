/// Telugu orthographic syllables, including virama-linked consonant clusters.
/// This deliberately does not use generic Unicode grapheme boundaries.
abstract final class TeluguAkshara {
  static bool _consonant(int c) =>
      (c >= 0x0c15 && c <= 0x0c28) ||
      (c >= 0x0c2a && c <= 0x0c39) ||
      (c >= 0x0c58 && c <= 0x0c5a);

  static bool _vowel(int c) =>
      (c >= 0x0c05 && c <= 0x0c0c) ||
      (c >= 0x0c0e && c <= 0x0c10) ||
      (c >= 0x0c12 && c <= 0x0c14) ||
      c == 0x0c60 ||
      c == 0x0c61;

  static bool _vowelSign(int c) =>
      (c >= 0x0c3e && c <= 0x0c44) ||
      (c >= 0x0c46 && c <= 0x0c48) ||
      (c >= 0x0c4a && c <= 0x0c4c) ||
      c == 0x0c62 ||
      c == 0x0c63;

  // AI is Telugu's canonically decomposable vowel sign. Joiners control
  // rendering of virama sequences but do not change crossword answers.
  static String normalize(String text) => text
      .replaceAll('\u0c46\u0c56', '\u0c48')
      .replaceAll(RegExp('[\u200c\u200d]'), '');

  static bool equivalent(String first, String second) =>
      normalize(first) == normalize(second);

  static List<String> split(String text) {
    final runes = text.replaceAll('\u0c46\u0c56', '\u0c48').runes.toList();
    final result = <String>[];
    var i = 0;
    while (i < runes.length) {
      final start = i;
      final consonant = _consonant(runes[i]);
      if (!consonant && !_vowel(runes[i])) {
        throw FormatException('Expected a Telugu letter at rune $i.', text);
      }
      i++;
      var terminalVirama = false;
      if (consonant) {
        while (i < runes.length && runes[i] == 0x0c4d) {
          i++;
          if (i < runes.length && (runes[i] == 0x200c || runes[i] == 0x200d)) {
            i++;
          }
          terminalVirama = true;
          if (i >= runes.length || !_consonant(runes[i])) break;
          i++;
          terminalVirama = false;
        }
        if (!terminalVirama && i < runes.length && _vowelSign(runes[i])) {
          i++;
        }
      }
      if (!terminalVirama &&
          i < runes.length &&
          runes[i] >= 0x0c00 &&
          runes[i] <= 0x0c04) {
        i++;
      }
      result.add(String.fromCharCodes(runes.sublist(start, i)));
    }
    return List.unmodifiable(result);
  }
}
