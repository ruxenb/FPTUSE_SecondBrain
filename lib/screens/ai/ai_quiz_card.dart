import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/quiz_question.dart';

class AIQuizCard extends StatefulWidget {
  const AIQuizCard({super.key, required this.questions});

  final List<QuizQuestion> questions;

  @override
  State<AIQuizCard> createState() => _AIQuizCardState();
}

class _AIQuizCardState extends State<AIQuizCard> {
  final Map<int, int> _selectedAnswers = {};
  final Set<int> _revealedAnswers = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < widget.questions.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildQuestion(index, widget.questions[index]),
          ),
      ],
    );
  }

  Widget _buildQuestion(int index, QuizQuestion question) {
    final selected = _selectedAnswers[index];
    final revealed = _revealedAnswers.contains(index);

    return Material(
      color: AppColors.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Câu ${index + 1}. ${question.question}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            RadioGroup<int>(
              groupValue: selected,
              onChanged: (value) {
                if (revealed || value == null) {
                  return;
                }
                setState(() {
                  _selectedAnswers[index] = value;
                });
              },
              child: Column(
                children: [
                  for (
                    var optionIndex = 0;
                    optionIndex < question.options.length;
                    optionIndex++
                  )
                    RadioListTile<int>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: optionIndex,
                      enabled: !revealed,
                      title: Text(
                        '${String.fromCharCode(65 + optionIndex)}. '
                        '${question.options[optionIndex]}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: selected == null
                    ? null
                    : () {
                        setState(() {
                          if (revealed) {
                            _revealedAnswers.remove(index);
                          } else {
                            _revealedAnswers.add(index);
                          }
                        });
                      },
                child: Text(revealed ? 'Ẩn đáp án' : 'Xem đáp án'),
              ),
            ),
            if (revealed) ...[
              const Divider(),
              Text(
                selected == question.correctIndex
                    ? 'Bạn đã chọn đúng.'
                    : 'Đáp án đúng: ${String.fromCharCode(65 + question.correctIndex)}.',
                style: TextStyle(
                  color: selected == question.correctIndex
                      ? AppColors.success
                      : AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                question.explanation,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
