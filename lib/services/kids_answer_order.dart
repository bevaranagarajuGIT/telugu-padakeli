import 'dart:math';

int newAnswerOrderSeed() => Random().nextInt(0x7fffffff);

List<T> orderedKidsChoices<T>(
  List<T> choices, {
  required bool Function(T) isAnswer,
  required int seed,
  required int questionIndex,
}) {
  if (choices.isEmpty) return const [];
  final order = List<T>.of(choices)..shuffle(Random(seed + questionIndex));
  final answer = order.firstWhere(isAnswer);
  order.remove(answer);
  // Balance answer positions in each group without changing the source content.
  final positions = List.generate(choices.length, (index) => index)
    ..shuffle(Random(seed + questionIndex ~/ choices.length));
  order.insert(positions[questionIndex % choices.length], answer);
  return List.unmodifiable(order);
}
