import 'package:flutter/material.dart';
import '../services/post_service.dart';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _postService = PostService();
  final _commentController = TextEditingController();

  List<dynamic> _comments = [];
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  int get _postId => widget.post['id'] as int;

  Future<void> _loadComments() async {
    try {
      final comments = await _postService.getPostComments(_postId);
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd pobierania komentarzy: $e')),
      );
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _submitting = true);

    try {
      await _postService.addPostComment(postId: _postId, comment: text);
      _commentController.clear();
      await _loadComments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd dodawania komentarza: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _deleteComment(int commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usuń komentarz'),
        content: const Text('Czy na pewno chcesz usunąć ten komentarz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await _postService.deletePostComment(commentId);
      if (!mounted) return;
      setState(() {
        _comments.removeWhere((c) => c['id'] == commentId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Komentarz został usunięty')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się usunąć komentarza: $e')),
      );
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw.length > 10 ? raw.substring(0, 10) : raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final title = post['title'] as String? ?? 'Post';
    final content = post['content'] as String? ?? '';
    final username = post['username'] as String? ?? 'Anonim';
    final createdAt = _formatDate(post['created_at'] as String?);

    return Scaffold(
      appBar: AppBar(title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              children: [
                // Karta posta
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: const Color(0xFF17283F),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline_rounded,
                              size: 16,
                              color: Color(0xFF168A83),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              username,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF168A83),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.access_time_rounded,
                              size: 15,
                              color: Color(0xFF728092),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              createdAt,
                              style: const TextStyle(
                                color: Color(0xFF728092),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Text(
                          content,
                          style: const TextStyle(
                            color: Color(0xFF17283F),
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Sekcja komentarzy
                Text(
                  'Komentarze (${_comments.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF17283F),
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_comments.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Brak komentarzy. Bądź pierwszy!',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                  )
                else
                  ..._comments.map<Widget>((c) {
                    final cId = c['id'] as int;
                    final cUser = c['username'] as String? ?? 'Użytkownik';
                    final cText = c['comment'] as String? ?? '';
                    final cDate = _formatDate(c['created_at'] as String?);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 14,
                                      color: Color(0xFF20A894),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      cUser,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF17283F),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      cDate,
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 16),
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      color: Colors.grey[400],
                                      tooltip: 'Usuń',
                                      onPressed: () => _deleteComment(cId),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              cText,
                              style: const TextStyle(
                                color: Color(0xFF17283F),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
          // Pole dodawania komentarza
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              8,
              MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE9EEF0)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Napisz komentarz...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      fillColor: const Color(0xFFF4F7F8),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _addComment(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _submitting ? null : _addComment,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

