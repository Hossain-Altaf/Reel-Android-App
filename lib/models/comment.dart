class Comment {
  final String id;
  final String userId;
  final String username;
  final String userAvatarUrl;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.username,
    required this.userAvatarUrl,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['_id'] ?? '',
      userId: json['user'] ?? '',
      username: json['username'] ?? '',
      userAvatarUrl: json['userAvatarUrl'] ?? '',
      text: json['text'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}