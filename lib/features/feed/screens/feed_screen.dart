import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/feed_provider.dart';
import '../widgets/reel_player.dart';
import '../../upload/screens/upload_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../chat/screen/inbox_screen.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> with SingleTickerProviderStateMixin {
  int _navIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildFeedList(AsyncValue<List<dynamic>> reelsAsync, dynamic providerToInvalidate) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(providerToInvalidate),
      child: reelsAsync.when(
        data: (reels) {
          if (reels.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 200),
                Center(
                  child: Text('No reels yet.', style: TextStyle(color: Colors.white70)),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final forYouAsync = ref.watch(reelsFeedProvider);
    final followingAsync = ref.watch(followingFeedProvider);

    final body = _navIndex == 0
        ? Column(
      children: [
        SafeArea(
          bottom: false,
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(text: 'For You'),
              Tab(text: 'Following'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildFeedList(forYouAsync, reelsFeedProvider),
              _buildFeedList(followingAsync, followingFeedProvider),
            ],
          ),
        ),
      ],
    )
        : const ProfileScreen();

    return Scaffold(
      body: body,
      floatingActionButton: _navIndex == 0
          ? FloatingActionButton(
        mini: true,
        backgroundColor: Colors.black54,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InboxScreen()),
        ),
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      )
          : null,
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
              ref.invalidate(followingFeedProvider);
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