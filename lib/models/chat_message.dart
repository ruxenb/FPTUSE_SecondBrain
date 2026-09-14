enum MessageSender { user, ai, system }

/// Đại diện cho một tin nhắn trong khung Chat AI hoặc phản hồi Summary.
/// Phụ trách: Member 3 (AI Assistant)
class ChatMessage {
  final String id;
  final MessageSender sender;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    DateTime? timestamp,

  }) : timestamp = timestamp ?? DateTime.now();
}
