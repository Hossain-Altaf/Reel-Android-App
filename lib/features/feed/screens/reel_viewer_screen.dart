import 'package:flutter/material.dart';
import '../../../models/reel.dart';
import '../widgets/reel_player.dart';

class ReelViewerScreen extends StatelessWidget {
  final List<Reel> reels;
  final int initialIndex;

  const ReelViewerScreen({
    super.key,
    required this.reels,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        controller: PageController(initialPage: initialIndex),
        itemCount: reels.length,
        itemBuilder: (context, index) => ReelPlayer(reel: reels[index]),
      ),
    );
  }
}