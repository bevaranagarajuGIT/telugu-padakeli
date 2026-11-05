class KidsQuestion {
  const KidsQuestion({
    required this.prompt,
    required this.answer,
    required this.hint,
    required this.options,
  });

  final String prompt;
  final String answer;
  final String hint;
  final List<String> options;
}

class KidsQuestionLevel {
  const KidsQuestionLevel({
    required this.name,
    required this.title,
    required this.questions,
  });

  final String name;
  final String title;
  final List<KidsQuestion> questions;
}
