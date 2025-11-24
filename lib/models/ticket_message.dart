class TicketMessage {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final DateTime timestamp;
  final bool isBot;
  final bool isAdmin;
  final String? role; // 'admin', 'moderator', or null

  TicketMessage({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    required this.timestamp,
    required this.isBot,
    this.isAdmin = false,
    this.role,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      authorName: json['author_name'] as String,
      authorAvatar: json['author_avatar'] as String?,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isBot: json['is_bot'] as bool? ?? false,
      isAdmin: json['is_admin'] as bool? ?? false,
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_id': authorId,
      'author_name': authorName,
      'author_avatar': authorAvatar,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'is_bot': isBot,
      'is_admin': isAdmin,
      'role': role,
    };
  }
}
