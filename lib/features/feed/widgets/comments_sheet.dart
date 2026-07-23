import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/comment.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/feed_provider.dart';

class CommentsSheet extends ConsumerStatefulWidget {
  final String reelId;
  const CommentsSheet({super.key, required this.reelId});

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final _controller = TextEditingController();
  List<Comment> _comments = [];
  bool _loading = true;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await ref.read(reelServiceProvider).fetchComments(widget.reelId);
      if (mounted) setState(() {
        _comments = comments;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _post() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _posting = true);
    try {
      final comment = await ref.read(reelServiceProvider).addComment(widget.reelId, text);
      setState(() {
        _comments.insert(0, comment);
        _controller.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _delete(Comment comment) async {
    try {
      await ref.read(reelServiceProvider).deleteComment(widget.reelId, comment.id);
      setState(() => _comments.removeWhere((c) => c.id == comment.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1C1C1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Comments',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _comments.isEmpty
                    ? const Center(
                  child: Text('No comments yet. Be the first!',
                      style: TextStyle(color: Colors.white54)),
                )
                    : ListView.builder(
                  controller: scrollController,
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    final comment = _comments[index];
                    final isMine = comment.userId == currentUser?.id;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: comment.userAvatarUrl.isNotEmpty
                            ? NetworkImage(comment.userAvatarUrl)
                            : null,
                        child: comment.userAvatarUrl.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text('@${comment.username}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(comment.text, style: const TextStyle(color: Colors.white70)),
                      trailing: isMine
                          ? IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.white54, size: 20),
                        onPressed: () => _delete(comment),
                      )
                          : null,
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: TextStyle(color: Colors.white38),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: _posting
                            ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send, color: Colors.white),
                        onPressed: _posting ? null : _post,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}