import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/reel.dart';
import '../../../models/app_user.dart';
import '../../../providers/feed_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/user_services.dart';
import '../../feed/screens/reel_viewer_screen.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  final String username;

  const UserProfileScreen({super.key, required this.userId, required this.username});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final _userService = UserService();
  AppUser? _user;
  bool? _following; // null until loaded
  int _followerCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await _userService.fetchUserById(widget.userId);
    if (mounted) {
      setState(() {
        _user = user;
        _following = user.isFollowedByMe;
        _followerCount = user.followerCount;
      });
    }
  }

  Future<void> _toggleFollow() async {
    setState(() {
      _following = !(_following ?? false);
      _followerCount += _following! ? 1 : -1;
    });
    try {
      final result = await _userService.toggleFollow(widget.userId);
      if (mounted) setState(() => _followerCount = result['followerCount']);
    } catch (_) {
      if (mounted) {
        setState(() {
          _following = !_following!;
          _followerCount += _following! ? 1 : -1;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isOwnProfile = currentUser?.id == widget.userId;

    return Scaffold(
      appBar: AppBar(title: Text('@${widget.username}')),
      body: FutureBuilder<List<Reel>>(
        future: ref.read(reelServiceProvider).fetchUserReels(widget.userId),
        builder: (context, reelsSnapshot) {
          if (reelsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (reelsSnapshot.hasError) {
            return Center(
              child: Text('Error: ${reelsSnapshot.error}', style: const TextStyle(color: Colors.white)),
            );
          }
          final reels = reelsSnapshot.data ?? [];

          return ListView(
            children: [
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 40,
                backgroundImage: (_user?.avatarUrl.isNotEmpty ?? false)
                    ? NetworkImage(_user!.avatarUrl)
                    : null,
                child: (_user?.avatarUrl.isEmpty ?? true) ? const Icon(Icons.person, size: 40) : null,
              ),
              const SizedBox(height: 8),
              Center(
                child: Text('@${widget.username}',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              if (_user?.bio.isNotEmpty ?? false)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(_user!.bio,
                      textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                ),
              const SizedBox(height: 8),
              Center(
                child: Text('$_followerCount followers',
                    style: const TextStyle(color: Colors.white54)),
              ),
              const SizedBox(height: 16),
              if (!isOwnProfile && _following != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: ElevatedButton(
                    onPressed: _toggleFollow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _following! ? Colors.grey.shade800 : null,
                    ),
                    child: Text(_following! ? 'Following' : 'Follow'),
                  ),
                ),
              const SizedBox(height: 16),
              if (reels.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('No reels yet.', style: TextStyle(color: Colors.white70)),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(4),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    childAspectRatio: 9 / 16,
                  ),
                  itemCount: reels.length,
                  itemBuilder: (context, index) {
                    final reel = reels[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReelViewerScreen(reels: reels, initialIndex: index),
                        ),
                      ),
                      child: reel.thumbnailUrl.isNotEmpty
                          ? CachedNetworkImage(imageUrl: reel.thumbnailUrl, fit: BoxFit.cover)
                          : Container(
                        color: Colors.grey.shade900,
                        child: const Icon(Icons.play_circle_outline, color: Colors.white54),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}