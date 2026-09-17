class QuizQuestion {
  QuizQuestion({
    required this.question,
    required List<String> options,
    required this.correctIndex,
    required this.explanation,
  }) : options = List.unmodifiable(options) {
    if (this.options.length != 4) {
      throw ArgumentError.value(
        this.options.length,
        'options',
        'A quiz question must contain exactly four options.',
      );
    }
    if (correctIndex < 0 || correctIndex >= this.options.length) {
      throw ArgumentError.value(
        correctIndex,
        'correctIndex',
        'The correct answer index is out of range.',
      );
    }
  }

  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    if (rawOptions is! List) {
      throw const FormatException('Quiz options must be a list.');
    }

    final options = rawOptions.map((item) => item.toString().trim()).toList();
    final correctIndex = _parseCorrectIndex(json['correctIndex']);

    return QuizQuestion(
      question: (json['question'] ?? '').toString().trim(),
      options: options,
      correctIndex: correctIndex,
      explanation: (json['explanation'] ?? '').toString().trim(),
    );
  }

  static int _parseCorrectIndex(Object? value) {
    if (value is int) {
      return value;
    }
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed == null) {
      throw const FormatException('Quiz correctIndex must be an integer.');
    }
    return parsed;
  }
}
