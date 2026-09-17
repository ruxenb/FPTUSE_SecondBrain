import '../core/constants/app_constants.dart';

class QuizQuestion {
  QuizQuestion({
    required this.question,
    required List<String> options,
    required this.correctIndex,
    required this.explanation,
  }) : options = List.unmodifiable(options) {
    if (question.trim().isEmpty) {
      throw ArgumentError.value(
        question,
        'question',
        'Question must not be empty.',
      );
    }
    if (this.options.length != AppConstants.quizOptionCount) {
      throw ArgumentError.value(
        this.options.length,
        'options',
        'A quiz question must contain exactly ${AppConstants.quizOptionCount} options.',
      );
    }
    if (this.options.any((option) => option.trim().isEmpty)) {
      throw ArgumentError.value(
        this.options,
        'options',
        'Quiz options must not be empty.',
      );
    }
    final normalizedOptions = this.options
        .map((option) => option.trim().toLowerCase())
        .toSet();
    if (normalizedOptions.length != this.options.length) {
      throw ArgumentError.value(
        this.options,
        'options',
        'Quiz options must be unique.',
      );
    }
    if (correctIndex < 0 || correctIndex >= this.options.length) {
      throw ArgumentError.value(
        correctIndex,
        'correctIndex',
        'The correct answer index is out of range.',
      );
    }
    if (explanation.trim().isEmpty) {
      throw ArgumentError.value(
        explanation,
        'explanation',
        'Explanation must not be empty.',
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
    if (rawOptions.any((item) => item is! String)) {
      throw const FormatException('Every quiz option must be a string.');
    }

    return QuizQuestion(
      question: _requiredString(json['question'], 'question'),
      options: rawOptions.cast<String>().map((item) => item.trim()).toList(),
      correctIndex: _parseCorrectIndex(json['correctIndex']),
      explanation: _requiredString(json['explanation'], 'explanation'),
    );
  }

  static String _requiredString(Object? value, String fieldName) {
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Quiz $fieldName must be a non-empty string.');
    }
    return value.trim();
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
