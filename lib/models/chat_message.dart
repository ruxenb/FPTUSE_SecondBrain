enum MessageSender { user, ai, system }

enum MessageKind { chat, summary }

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    this.kind = MessageKind.chat,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String id;
  final MessageSender sender;
  final String text;
  final MessageKind kind;
  final DateTime timestamp;
}
