import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/feed_provider.dart';
import '../widgets/reel_player.dart';
import '../../upload/screens/upload_screen.dart';
import '../../profile/screens/profile_screen.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final reelsAsync = ref.watch(reelsFeedProvider);

    final body = _navIndex == 0
        ? RefreshIndicator(
      onRefresh: () async => ref.invalidate(reelsFeedProvider),
      child: reelsAsync.when(
        data: (reels) {
          if (reels.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 200),
                Center(
                  child: Text('No reels yet. Be the first to upload!',
                      style: TextStyle(color: Colors.white70)),
                ),
              ],
            );
          }
          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: reels.length,
            itemBuilder: (context, index) => ReelPlayer(reel: reels[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error loading feed: $e', style: const TextStyle(color: Colors.white)),
        ),
      ),
    )
        : const ProfileScreen();

    return Scaffold(
      //extendBody: true,
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        currentIndex: _navIndex,
        onTap: (i) async {
          if (i == 1) {
            final uploaded = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UploadScreen()),
            );
            if (uploaded == true) {
              ref.invalidate(reelsFeedProvider);
            }
            return;
          }
          setState(() => _navIndex = i == 2 ? 1 : 0);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), label: 'Upload'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}