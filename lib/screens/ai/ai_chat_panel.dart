import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/chat_message.dart';
import '../../providers/ai_provider.dart';
import '../../providers/note_provider.dart';
import 'ai_quiz_card.dart';

/// Panel tương tác với Trợ lý AI: Chat, Tóm tắt Note, Tạo Quiz.
/// Phụ trách: Member 3
class AIChatPanel extends StatefulWidget {
  const AIChatPanel({super.key});

  @override
  State<AIChatPanel> createState() => _AIChatPanelState();
}

class _AIChatPanelState extends State<AIChatPanel> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final aiProvider = context.watch<AIProvider>();
    final noteProvider = context.watch<NoteProvider>();
    final currentNote = noteProvider.currentNote;

    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          // Header Panel
          _buildHeader(context, aiProvider),
          const Divider(height: 1),

          // Nút bấm thao tác nhanh (Quick Actions)
          _buildQuickActionButtons(context, aiProvider, currentNote),
          const Divider(height: 1),

          // Lịch sử tin nhắn Chat
          Expanded(
            child: aiProvider.messages.isEmpty
                ? _buildEmptyPrompt()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: aiProvider.messages.length,
                    itemBuilder: (ctx, index) {
                      final msg = aiProvider.messages[index];
                      return _buildMessageBubble(msg);
                    },
                  ),
          ),

          // Thanh trạng thái loading
          if (aiProvider.isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surfaceVariant.withAlpha(80),
              child: const Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Gemini AI đang suy nghĩ...',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

          // Khung nhập tin nhắn
          _buildInputBar(aiProvider),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AIProvider aiProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 18, color: AppColors.secondary),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'AI STUDY ASSISTANT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, size: 18),
            tooltip: 'Xóa lịch sử chat',
            onPressed: aiProvider.messages.isNotEmpty ? () => aiProvider.clearMessages() : null,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButtons(BuildContext context, AIProvider aiProvider, dynamic currentNote) {
    final hasNote = currentNote != null;

    return Container(
      padding: const EdgeInsets.all(8),
      color: AppColors.background.withAlpha(100),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: hasNote && !aiProvider.isLoading
                  ? () {
                      aiProvider.summarizeNote(currentNote.title, currentNote.content);
                      _scrollToBottom();
                    }
                  : null,
              icon: const Icon(Icons.bolt, size: 15, color: Colors.amber),
              label: const Text('Tóm tắt Note', style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                side: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: hasNote && !aiProvider.isLoading
                  ? () {
                      aiProvider.generateQuiz(currentNote.title, currentNote.content);
                      _scrollToBottom();
                    }
                  : null,
              icon: const Icon(Icons.school_outlined, size: 15, color: AppColors.secondary),
              label: const Text('Tạo 3 Quiz', style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                side: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology_outlined, size: 48, color: AppColors.textDisabled.withAlpha(100)),
            const SizedBox(height: 12),
            const Text(
              'Trợ lý học tập FPTU SE sẵn sàng!',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Bấm "Tóm tắt Note" hoặc "Tạo 3 Quiz" để ôn thi các môn PRM393, PRN231, SWE201...',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textDisabled, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.sender == MessageSender.user;

    if (msg.isQuiz) {
      return AIQuizCard(quizText: msg.text);
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(10),
            topRight: const Radius.circular(10),
            bottomLeft: Radius.circular(isUser ? 10 : 2),
            bottomRight: Radius.circular(isUser ? 2 : 10),
          ),
        ),
        child: SelectableText(
          msg.text,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: isUser ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(AIProvider aiProvider) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              decoration: const InputDecoration(
                hintText: 'Hỏi AI về kiến thức môn học...',
                isDense: true,
              ),
              onSubmitted: (val) => _handleSend(aiProvider),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send_rounded, size: 18, color: AppColors.primary),
            onPressed: () => _handleSend(aiProvider),
          ),
        ],
      ),
    );
  }

  void _handleSend(AIProvider aiProvider) {
    final text = _inputController.text.trim();
    if (text.isNotEmpty) {
      aiProvider.sendMessage(text);
      _inputController.clear();
      _scrollToBottom();
    }
  }
}
