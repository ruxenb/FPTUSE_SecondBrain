import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Thẻ hiển thị câu hỏi trắc nghiệm hoặc nội dung Quiz từ AI.
/// Phụ trách: Member 3
class AIQuizCard extends StatelessWidget {
  final String quizText;

  const AIQuizCard({super.key, required this.quizText});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withAlpha(120), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.quiz_outlined, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'QUIZ ÔN TẬP BÀI HỌC',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            quizText,
            style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
