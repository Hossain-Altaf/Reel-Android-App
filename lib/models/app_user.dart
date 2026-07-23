class AppUser {
  final String id;
  final String username;
  final String email;
  final String bio;
  final String avatarUrl;
  final int followerCount;
  final int followingCount;
  final bool isFollowedByMe;

  AppUser({
    required this.id,
    required this.username,
    required this.email,
    this.bio = '',
    this.avatarUrl = '',
    this.followerCount = 0,
    this.followingCount = 0,
    this.isFollowedByMe = false,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? json['_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      bio: json['bio'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      followerCount: json['followerCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      isFollowedByMe: json['isFollowedByMe'] ?? false,
    );
  }
}