class Conversation {
  final String id;
  final String otherUserId;
  final String otherUsername;
  final String otherUserAvatarUrl;
  final String lastMessageText;
  final DateTime lastMessageAt;

  Conversation({
    required this.id,
    required this.otherUserId,
    required this.otherUsername,
    required this.otherUserAvatarUrl,
    required this.lastMessageText,
    required this.lastMessageAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final otherUser = json['otherUser'];
    return Conversation(
      id: json['_id'] ?? '',
      otherUserId: otherUser?['id'] ?? '',
      otherUsername: otherUser?['username'] ?? '',
      otherUserAvatarUrl: otherUser?['avatarUrl'] ?? '',
      lastMessageText: json['lastMessageText'] ?? '',
      lastMessageAt: DateTime.tryParse(json['lastMessageAt'] ?? '') ?? DateTime.now(),
    );
  }
}