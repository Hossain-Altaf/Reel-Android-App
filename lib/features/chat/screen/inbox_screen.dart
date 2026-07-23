import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/conversation.dart';
import '../../../providers/chat_provider.dart';
import 'chat_screen.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  List<Conversation>? _conversations;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final conversations = await ref.read(chatServiceProvider).fetchConversations();
    if (mounted) setState(() => _conversations = conversations);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: _conversations == null
          ? const Center(child: CircularProgressIndicator())
          : _conversations!.isEmpty
          ? const Center(
        child: Text('No conversations yet.', style: TextStyle(color: Colors.white70)),
      )
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          itemCount: _conversations!.length,
          itemBuilder: (context, index) {
            final conv = _conversations![index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: conv.otherUserAvatarUrl.isNotEmpty
                    ? NetworkImage(conv.otherUserAvatarUrl)
                    : null,
                child: conv.otherUserAvatarUrl.isEmpty ? const Icon(Icons.person) : null,
              ),
              title: Text('@${conv.otherUsername}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(
                conv.lastMessageText.isEmpty ? 'Say hello!' : conv.lastMessageText,
                style: const TextStyle(color: Colors.white54),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    conversationId: conv.id,
                    otherUsername: conv.otherUsername,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}