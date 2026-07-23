import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/feed_provider.dart';
import '../../../models/reel.dart';
import '../../feed/screens/reel_viewer_screen.dart';
import 'edit_profile_screen.dart';
import '../../../models/app_user.dart';
import '../../../services/user_services.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  List<Reel>? _reels;
  bool _loading = true;
  AppUser? _fullUser;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _loading = true);
    final results = await Future.wait([
      ref.read(reelServiceProvider).fetchUserReels(user.id),
      UserService().fetchUserById(user.id),
    ]);
    if (mounted) setState(() {
      _reels = results[0] as List<Reel>;
      _fullUser = results[1] as AppUser;
      _loading = false;
    });
  }

  Future<void> _confirmDelete(Reel reel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this reel?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(reelServiceProvider).deleteReel(reel.id);
        setState(() => _reels!.removeWhere((r) => r.id == reel.id));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          if (_fullUser != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text('${_reels?.length ?? 0}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      const Text('Reels', style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('${_fullUser!.followerCount}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      const Text('Followers', style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('${_fullUser!.followingCount}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      const Text('Following', style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                ],
              ),
            ),
          Expanded(
            child: (_reels?.isEmpty ?? true)
                ? const Center(
              child: Text("You haven't posted any reels yet.",
                  style: TextStyle(color: Colors.white70)),
            )
                : RefreshIndicator(
              onRefresh: _load,
              child: GridView.builder(
                padding: const EdgeInsets.all(4),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 9 / 16,
                ),
                itemCount: _reels!.length,
                itemBuilder: (context, index) {
                  final reel = _reels![index];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ReelViewerScreen(reels: _reels!, initialIndex: index),
                      ),
                    ),
                    onLongPress: () => _confirmDelete(reel),
                    child: reel.thumbnailUrl.isNotEmpty
                        ? CachedNetworkImage(
                        imageUrl: reel.thumbnailUrl, fit: BoxFit.cover)
                        : Container(
                      color: Colors.grey.shade900,
                      child: const Icon(Icons.play_circle_outline,
                          color: Colors.white54),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}