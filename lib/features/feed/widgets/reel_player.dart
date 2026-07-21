import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/reel.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/feed_provider.dart';
import '../../profile/screens/user_profile_screen.dart';

class ReelPlayer extends ConsumerStatefulWidget {
  final Reel reel;
  const ReelPlayer({super.key, required this.reel});

  @override
  ConsumerState<ReelPlayer> createState() => _ReelPlayerState();
}

class _ReelPlayerState extends ConsumerState<ReelPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _isVisible = false;
  late bool _liked;
  late int _likeCount;
  bool _hasCountedView = false;
  bool _showPauseIcon = false;

  @override
  void initState() {
    super.initState();
    final currentUser = ref.read(currentUserProvider);
    _liked = widget.reel.isLikedBy(currentUser?.id);
    _likeCount = widget.reel.likeCount;

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.reel.videoUrl))
      ..setLooping(true)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _initialized = true);
        // The video may have finished loading AFTER we already scrolled to it.
        // If we're still the visible page, start playing now instead of
        // waiting for a visibility change that already happened.
        if (_isVisible) {
          _controller.play();
          _countViewIfNeeded();
        }
      });
  }

  void _countViewIfNeeded() {
    if (!_hasCountedView) {
      _hasCountedView = true;
      ref.read(reelServiceProvider).incrementView(widget.reel.id);
    }
  }

  Future<void> _toggleLike() async {
    setState(() {
      _liked = !_liked;
      _likeCount += _liked ? 1 : -1;
    });
    try {
      final serverCount = await ref.read(reelServiceProvider).toggleLike(widget.reel.id);
      if (mounted) setState(() => _likeCount = serverCount);
    } catch (_) {
      if (mounted) {
        setState(() {
          _liked = !_liked;
          _likeCount += _liked ? 1 : -1;
        });
      }
    }
  }

  void _togglePlayPause() {
    if (!_initialized) return;
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _showPauseIcon = true;
      } else {
        _controller.play();
        _showPauseIcon = false;
      }
    });
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final nowVisible = info.visibleFraction > 0.8;
    _isVisible = nowVisible;

    if (!_initialized) return; // will be handled by the initialize().then() callback once ready

    if (nowVisible) {
      _controller.play();
      setState(() => _showPauseIcon = false);
      _countViewIfNeeded();
    } else {
      _controller.pause();
    }
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(userId: widget.reel.userId, username: widget.reel.username),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('reel-${widget.reel.id}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _initialized
              ? GestureDetector(
            onTap: _togglePlayPause,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          )
              : const Center(child: CircularProgressIndicator()),

          if (_showPauseIcon)
            const Center(
              child: Icon(Icons.play_arrow, color: Colors.white70, size: 80),
            ),

          if (_initialized)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                padding: EdgeInsets.zero,
                colors: const VideoProgressColors(
                  playedColor: Colors.white,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white10,
                ),
              ),
            ),

          Positioned(
            right: 12,
            bottom: 100,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _openProfile,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundImage: widget.reel.userAvatarUrl.isNotEmpty
                        ? NetworkImage(widget.reel.userAvatarUrl)
                        : null,
                    child: widget.reel.userAvatarUrl.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                IconButton(
                  icon: Icon(
                    _liked ? Icons.favorite : Icons.favorite_border,
                    color: _liked ? Colors.red : Colors.white,
                    size: 32,
                  ),
                  onPressed: _toggleLike,
                ),
                Text('$_likeCount', style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),

          Positioned(
            left: 12,
            right: 80,
            bottom: 30,
            child: GestureDetector(
              onTap: _openProfile,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('@${widget.reel.username}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(widget.reel.caption, style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}