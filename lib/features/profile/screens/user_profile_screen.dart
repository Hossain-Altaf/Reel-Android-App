import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/reel.dart';
import '../../../models/app_user.dart';
import '../../../providers/feed_provider.dart';
import '../../../services/user_services.dart';
import '../../feed/screens/reel_viewer_screen.dart';

class UserProfileScreen extends ConsumerWidget {
  final String userId;
  final String username; // shown immediately while full profile loads

  const UserProfileScreen({super.key, required this.userId, required this.username});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('@$username')),
      body: FutureBuilder<AppUser>(
        future: UserService().fetchUserById(userId),
        builder: (context, userSnapshot) {
          return FutureBuilder<List<Reel>>(
            future: ref.read(reelServiceProvider).fetchUserReels(userId),
            builder: (context, reelsSnapshot) {
              if (reelsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (reelsSnapshot.hasError) {
                return Center(
                  child: Text('Error: ${reelsSnapshot.error}',
                      style: const TextStyle(color: Colors.white)),
                );
              }
              final reels = reelsSnapshot.data ?? [];
              final user = userSnapshot.data;

              return ListView(
                children: [
                  const SizedBox(height: 16),
                  CircleAvatar(
                    radius: 40,
                    backgroundImage:
                    (user?.avatarUrl.isNotEmpty ?? false) ? NetworkImage(user!.avatarUrl) : null,
                    child: (user?.avatarUrl.isEmpty ?? true) ? const Icon(Icons.person, size: 40) : null,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text('@$username',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  if (user?.bio.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Text(user!.bio,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70)),
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
          );
        },
      ),
    );
  }
}