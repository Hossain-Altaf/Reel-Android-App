class Reel {
  final String id;
  final String userId;
  final String username;
  final String userAvatarUrl;
  final String videoUrl;
  final String thumbnailUrl;
  final String caption;
  final int likeCount;
  final int viewCount;
  final List<String> likedBy;
  final DateTime createdAt;

  Reel({
    required this.id,
    required this.userId,
    required this.username,
    required this.userAvatarUrl,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.caption,
    this.likeCount = 0,
    this.viewCount = 0,
    this.likedBy = const [],
    required this.createdAt,
  });

  factory Reel.fromJson(Map<String, dynamic> json) {
    return Reel(
      id: json['_id'] ?? '',
      userId: json['user'] ?? '',
      username: json['username'] ?? '',
      userAvatarUrl: json['userAvatarUrl'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      caption: json['caption'] ?? '',
      likeCount: json['likeCount'] ?? 0,
      viewCount: json['viewCount'] ?? 0,
      likedBy: List<String>.from(json['likedBy'] ?? []),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  bool isLikedBy(String? userId) => userId != null && likedBy.contains(userId);
}