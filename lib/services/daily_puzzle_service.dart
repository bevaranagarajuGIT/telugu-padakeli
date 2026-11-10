import '../core/learning_progress.dart';
import '../models/puzzle.dart';

class DailyPuzzleService {
  const DailyPuzzleService();

  Puzzle choose(List<Puzzle> puzzles, String date, LearningProgress progress) {
    if (puzzles.isEmpty) throw const FormatException('No local daily puzzles.');
    final saved = progress.daily(date);
    if (saved.isNotEmpty) {
      final match = puzzles
          .where((puzzle) => puzzle.id == saved['id'])
          .firstOrNull;
      if (match == null) {
        throw const FormatException(
          'The saved daily puzzle is no longer available.',
        );
      }
      return match;
    }
    final day = DateTime.tryParse(date);
    if (day == null || calendarDay(day) != date) {
      throw const FormatException('Invalid daily-puzzle date.');
    }
    final pool = [...puzzles]..sort((a, b) => a.id.compareTo(b.id));
    final ordinal = DateTime.utc(
      day.year,
      day.month,
      day.day,
    ).difference(DateTime.utc(2026, 1, 1)).inDays;
    final puzzle = pool[ordinal % pool.length];
    progress.chooseDaily(date, {
      'id': puzzle.id,
      'repeat': ordinal >= pool.length || ordinal < 0,
      'poolSize': pool.length,
    });
    return puzzle;
  }
}
