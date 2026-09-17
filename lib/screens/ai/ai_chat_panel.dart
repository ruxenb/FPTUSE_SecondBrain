import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/chat_message.dart';
import '../../providers/ai_provider.dart';
import '../../providers/note_provider.dart';
import 'ai_quiz_card.dart';

class AIChatPanel extends StatefulWidget {
  const AIChatPanel({super.key});

  @override
  State<AIChatPanel> createState() => _AIChatPanelState();
}

class _AIChatPanelState extends State<AIChatPanel> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int _lastMessageCount = 0;
  int _lastQuizCount = 0;
  bool _lastLoadingState = false;
  String? _lastNotePath;
  bool _noteContextInitialized = false;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiProvider = context.watch<AIProvider>();
    final noteProvider = context.watch<NoteProvider>();
    final currentNote = noteProvider.currentNote;

    _scheduleNoteContextSync(aiProvider, currentNote?.path);
    _scheduleScrollIfNeeded(aiProvider);

    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          _buildHeader(aiProvider),
          const Divider(height: 1),
          _buildQuickActions(
            aiProvider,
            currentNote?.title,
            currentNote?.content,
          ),
          if (aiProvider.hasError) _buildError(aiProvider),
          const Divider(height: 1),
          Expanded(child: _buildConversation(aiProvider)),
          const Divider(height: 1),
          _buildInput(aiProvider, currentNote?.title, currentNote?.content),
        ],
      ),
    );
  }

  Widget _buildHeader(AIProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_outlined,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'AI Assistant',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Xóa lịch sử',
            onPressed: provider.messages.isEmpty && !provider.hasQuiz
                ? null
                : provider.clearMessages,
            icon: const Icon(Icons.delete_outline, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(
    AIProvider provider,
    String? noteTitle,
    String? noteContent,
  ) {
    final hasNote = noteTitle != null && noteContent != null;
    final enabled = hasNote && !provider.isLoading;

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.tonal(
            onPressed: enabled
                ? () => provider.summarizeNote(noteTitle, noteContent)
                : null,
            child: const Text('Tóm tắt Note này'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: enabled
                ? () => provider.generateQuiz(noteTitle, noteContent)
                : null,
            child: const Text('Tạo 3 câu Quiz'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(AIProvider provider) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(24),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.error.withAlpha(100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              provider.errorMessage ?? '',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Đóng',
            onPressed: provider.clearError,
            icon: const Icon(Icons.close, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildConversation(AIProvider provider) {
    if (provider.messages.isEmpty && !provider.hasQuiz && !provider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Mở một Note để tóm tắt, tạo quiz hoặc đặt câu hỏi cho trợ lý AI.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textDisabled, fontSize: 12),
          ),
        ),
      );
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(10),
      children: [
        for (final message in provider.messages) _buildMessage(message),
        if (provider.hasQuiz) ...[
          const Padding(
            padding: EdgeInsets.only(top: 4, bottom: 10),
            child: Text(
              'Quiz ôn tập',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          AIQuizCard(questions: provider.quizQuestions),
        ],
        if (provider.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text(
                  'AI đang xử lý...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final isUser = message.sender == MessageSender.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 285),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primary.withAlpha(55)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isUser ? AppColors.primary.withAlpha(100) : AppColors.border,
          ),
        ),
        child: isUser
            ? SelectableText(
                message.text,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                ),
              )
            : MarkdownBody(
                data: message.text,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                  strong: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  code: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 11,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildInput(
    AIProvider provider,
    String? noteTitle,
    String? noteContent,
  ) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              enabled: !provider.isLoading,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(provider, noteTitle, noteContent),
              decoration: const InputDecoration(
                hintText: 'Hỏi về bài học hoặc code...',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Gửi',
            onPressed: provider.isLoading
                ? null
                : () => _send(provider, noteTitle, noteContent),
            icon: const Icon(Icons.send, size: 18),
          ),
        ],
      ),
    );
  }

  void _send(AIProvider provider, String? noteTitle, String? noteContent) {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      return;
    }

    _inputController.clear();
    provider.sendMessage(text, noteTitle: noteTitle, noteContent: noteContent);
  }

  void _scheduleNoteContextSync(AIProvider provider, String? notePath) {
    if (_noteContextInitialized && _lastNotePath == notePath) {
      return;
    }

    _noteContextInitialized = true;
    _lastNotePath = notePath;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      provider.setActiveNote(notePath);
    });
  }

  void _scheduleScrollIfNeeded(AIProvider provider) {
    final changed =
        _lastMessageCount != provider.messages.length ||
        _lastQuizCount != provider.quizQuestions.length ||
        _lastLoadingState != provider.isLoading;

    _lastMessageCount = provider.messages.length;
    _lastQuizCount = provider.quizQuestions.length;
    _lastLoadingState = provider.isLoading;

    if (!changed) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }
}
