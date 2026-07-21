import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/feed_provider.dart';
import '../../../models/reel.dart';
import '../../feed/screens/reel_viewer_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reels'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: FutureBuilder<List<Reel>>(
        future: ref.read(reelServiceProvider).fetchUserReels(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
            );
          }
          final reels = snapshot.data ?? [];
          if (reels.isEmpty) {
            return const Center(
              child: Text("You haven't posted any reels yet.",
                  style: TextStyle(color: Colors.white70)),
            );
          }
          return GridView.builder(
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
          );
        },
      ),
    );
  }
}