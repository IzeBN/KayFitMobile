class ChatMessage {
  final int? id;
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime createdAt;
  final bool isLoading;

  const ChatMessage({
    this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.isLoading = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as int?,
        role: json['role'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
