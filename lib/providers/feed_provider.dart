import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reel.dart';
import '../services/reel_service.dart';

final reelServiceProvider = Provider<ReelService>((ref) => ReelService());

final reelsFeedProvider = FutureProvider<List<Reel>>((ref) {
  return ref.watch(reelServiceProvider).fetchFeed();
});