import 'package:flutter_test/flutter_test.dart';
import 'package:telugu_padakeli/models/puzzle.dart';
import 'package:telugu_padakeli/models/telugu_akshara.dart';

void main() {
  for (final akshara in [
    'క',
    'కా',
    'కి',
    'కీ',
    'కు',
    'కూ',
    'కృ',
    'కౄ',
    'కె',
    'కే',
    'కై',
    'కొ',
    'కో',
    'కౌ',
    'క్ష',
    'క్షి',
    'స్త్రీ',
    'మ్మ',
    'ల్లు',
    'శం',
    'ఖం',
    'ఋ',
    'ఔ',
    'క్',
    'క\u0c46\u0c56',
    'క్\u200dషి',
    'క్\u200cషి',
  ]) {
    test('one orthographic cell: $akshara', () {
      expect(TeluguAkshara.split(akshara), hasLength(1));
    });
  }
  for (final entry in {
    'ఆకాశం': ['ఆ', 'కా', 'శం'],
    'అమ్మ': ['అ', 'మ్మ'],
    'ఇల్లు': ['ఇ', 'ల్లు'],
    'స్వాతంత్ర్యం': ['స్వా', 'తం', 'త్ర్యం'],
    'క్షమ': ['క్ష', 'మ'],
    'స్త్రీలు': ['స్త్రీ', 'లు'],
    'పర్యావరణం': ['ప', 'ర్యా', 'వ', 'ర', 'ణం'],
  }.entries) {
    test('syllable boundaries: ${entry.key}', () {
      expect(TeluguAkshara.split(entry.key), entry.value);
    });
  }
  for (final invalid in [
    'ి',
    '్క',
    'ం',
    'ః',
    'కాి',
    'కంం',
    'అా',
    'కa',
    'క క',
    'క\u200d',
    'క్\u200d\u200dష',
    'క్ి',
    '🙂',
  ]) {
    test('reject malformed Telugu: $invalid', () {
      expect(() => TeluguAkshara.split(invalid), throwsFormatException);
    });
  }
  test('Telugu canonical vowel decomposition and conjunct joiners compare', () {
    expect(TeluguAkshara.equivalent('కై', 'క\u0c46\u0c56'), isTrue);
    expect(TeluguAkshara.equivalent('క్షి', 'క్\u200dషి'), isTrue);
    expect(TeluguAkshara.equivalent('క్షి', 'క్\u200cషి'), isTrue);
    expect(TeluguAkshara.equivalent('క', 'కా'), isFalse);
    expect(TeluguAkshara.equivalent('ఖం', 'కం'), isFalse);
  });

  Puzzle puzzle(
    List<List<String>> rows,
    List<PuzzleClue> across,
    List<PuzzleClue> down,
  ) => Puzzle(
    id: 1,
    level: 'beginner',
    gridSize: rows.length,
    rows: rows,
    acrossClues: across,
    downClues: down,
  );
  PuzzleClue clue(
    String answer, {
    int row = 0,
    int column = 0,
    int number = 1,
  }) => PuzzleClue(
    number: number,
    clue: 'పరీక్ష',
    answer: answer,
    row: row,
    column: column,
  );

  test('clue lengths count Telugu aksharas rather than Unicode characters', () {
    for (final entry in {
      'ఆకాశం': 3,
      'అమ్మ': 2,
      'స్వాతంత్ర్యం': 3,
      'పర్యావరణం': 5,
      'క\u0c46\u0c56': 1,
      'క్\u200dషి': 1,
      'క్\u200cషి': 1,
    }.entries) {
      expect(clue(entry.key).aksharaCount, entry.value, reason: entry.key);
    }
  });

  test('canonical equivalent aksharas validate at an intersection', () {
    final p = puzzle(
      [
        ['క\u0c46\u0c56', 'క'],
        ['క', '#'],
      ],
      [clue('కైక')],
      [clue('కైక')],
    );
    expect(p.validate, returnsNormally);
  });
  test('crossing disagreement is rejected', () {
    final p = puzzle(
      [
        ['క', 'మ'],
        ['ల', '#'],
      ],
      [clue('కమ')],
      [clue('గల')],
    );
    expect(p.validate, throwsFormatException);
  });
  test('joined text equality cannot conceal split conjunct cells', () {
    final p = puzzle(
      [
        ['అ', 'మ్', 'మ'],
        ['#', '#', '#'],
        ['#', '#', '#'],
      ],
      [clue('అమ్మ')],
      [],
    );
    expect(p.validate, throwsFormatException);
  });
  test('two syllables in one cell are rejected', () {
    final p = puzzle(
      [
        ['అమ్మ'],
      ],
      [clue('అమ్మ')],
      [],
    );
    expect(p.validate, throwsFormatException);
  });
  test('omitted crossing clue is rejected even if cells are covered', () {
    final p = puzzle(
      [
        ['క', 'మ'],
        ['ల', 'త'],
      ],
      [clue('కమ'), clue('లత', row: 1, number: 2)],
      [],
    );
    expect(p.validate, throwsFormatException);
  });
  test('disconnected words are rejected', () {
    final p = puzzle(
      [
        ['క', 'మ', '#'],
        ['#', '#', '#'],
        ['ల', 'త', '#'],
      ],
      [clue('కమ'), clue('లత', row: 2, number: 2)],
      [],
    );
    expect(p.validate, throwsFormatException);
  });
}
