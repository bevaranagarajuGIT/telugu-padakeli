import 'dart:convert';
import 'dart:io';
import 'package:telugu_padakeli/models/telugu_akshara.dart';

import 'package:telugu_padakeli/services/kids_learning_service.dart';
import 'package:telugu_padakeli/services/kids_question_service.dart';

void main() {
  final file = File(
    'assets${Platform.pathSeparator}data${Platform.pathSeparator}content_review.json',
  );
  final previous = <String, Map<String, dynamic>>{};
  if (file.existsSync()) {
    final old = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    for (final item in old['items'] as List) {
      final row = Map<String, dynamic>.from(item as Map);
      previous[row['id'] as String] = row;
    }
  }
  final items = <Map<String, dynamic>>[];
  void add(Map<String, dynamic> item) {
    final old = previous[item['id']];
    final signature = jsonEncode(item);
    item['contentSignature'] = signature;
    item['reviewStatus'] = 'pending-human-review';
    item['reviewerNotes'] = old?['reviewerNotes'] ?? '';
    if (old?['contentSignature'] == signature) {
      item['reviewStatus'] = old?['reviewStatus'] ?? 'pending-human-review';
    }
    items.add(item);
  }

  for (final activity in const KidsLearningService().getActivities()) {
    activity.validate();
    for (final question in activity.questions) {
      add({
        'id': 'kids:${activity.id}:${question.id}',
        'activity': activity.id,
        'category': activity.categories.map((item) => item.title).toList(),
        'type': activity.type.name,
        'difficulty': question.difficulty,
        'prompt': question.prompt,
        'display': question.display,
        'answer': question.answer,
        'completedWord': question.completedWord,
        'distractors': question.choices
            .where((item) => item.telugu != question.answer)
            .map((item) => item.telugu)
            .toList(),
        'tiles': question.tiles,
        'explanation': question.explanation,
        'englishHelper': {
          'prompt': question.englishPrompt,
          'explanation': question.englishExplanation,
          'choices': {
            for (final choice in question.choices)
              choice.telugu: choice.english,
          },
        },
        'picture': question.imageAsset,
        'pictureDescription': question.imageDescription,
        'audio': question.audioAsset,
        'recordingScript': question.completedWord ?? question.answer,
      });
    }
  }
  for (final level in const KidsQuestionService().getLevels()) {
    for (final question in level.questions) {
      question.validate();
      add({
        'id': 'practice:${level.name}:${question.prompt}',
        'category': level.title,
        'difficulty': level.difficulty,
        'prompt': question.prompt,
        'answer': question.answer,
        'completedWord': question.completedWord,
        'distractors': question.options
            .where((item) => item != question.answer)
            .toList(),
        'explanation': question.hint,
        'englishHelper': question.englishHint,
        'picture': null,
        'audio': null,
        'recordingScript': question.completedWord,
      });
    }
  }
  final puzzles =
      jsonDecode(
            File(
              'assets${Platform.pathSeparator}data${Platform.pathSeparator}sample_puzzles.json',
            ).readAsStringSync(),
          )
          as List;
  for (final puzzle in puzzles) {
    for (final direction in ['across', 'down']) {
      for (final clue in puzzle['clues'][direction]) {
        add({
          'id': 'classic:${puzzle['id']}:$direction:${clue['number']}',
          'category': puzzle['level'],
          'difficulty': puzzle['level'],
          'prompt': clue['clue'],
          'answer': clue['answer'],
          'distractors': [],
          'explanation': clue['hint'],
          'englishHelper': null,
          'picture': null,
          'audio': null,
          'recordingScript': clue['answer'],
        });
      }
    }
  }
  final words = <String, List<String>>{};
  for (final item in items) {
    final word = TeluguAkshara.normalize(
      (item['completedWord'] ?? item['answer']) as String,
    );
    words.putIfAbsent(word, () => []).add(item['id'] as String);
  }
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': 1,
      'reviewPolicy': 'Automated structural checks are not Telugu educator approval. '
          'Review spelling, akshara boundaries, natural clues, English translations, '
          'distractor ambiguity and age suitability. No item has been human-approved by this export.',
      'repetitionPolicy': 'Shared words across picture, letter, completion and builder modes '
          'are intentional practice, not unique vocabulary growth. Review the groups below.',
      'repeatedVocabulary': words.entries.where((entry) => entry.value.length > 1).map((entry) => {'word': entry.key, 'ids': entry.value}).toList(),
      'items': items,
    })}\n',
  );
  stdout.writeln(
    'Exported ${items.length} content-review rows; reviewer notes preserved by stable ID.',
  );
}
