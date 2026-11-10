import 'package:flutter/material.dart';
import '../services/post_service.dart';
import '../services/game_service.dart';
import 'post_detail_screen.dart';

class PostsScreen extends StatefulWidget {
  final int? gameId;
  final String? gameTitle;

  const PostsScreen({
    super.key,
    this.gameId,
    this.gameTitle,
  });

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final _postService = PostService();
  final _gameService = GameService();

  List<dynamic> _posts = [];
  bool _loading = true;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _loading = true);

    try {
      final data = await _postService.getPosts(
        gameId: widget.gameId,
        page: _currentPage,
      );

      if (!mounted) return;
      setState(() {
        _posts = data['results'] ?? [];
        final count = data['count'] ?? 0;
        const pageSize = 20;
        _totalPages = (count / pageSize).ceil();
        if (_totalPages < 1) _totalPages = 1;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd ładowania postów: $e')),
      );
    }
  }

  Future<void> _showCreatePostDialog() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    int? selectedGameId = widget.gameId;
    String? selectedGameName = widget.gameTitle;
    List<dynamic> availableGames = [];
    bool loadingGames = false;

    if (selectedGameId == null) {
      loadingGames = true;
      try {
        final data = await _gameService.getGames(page: 1);
        availableGames = data['results'] ?? [];
        if (availableGames.isNotEmpty) {
          selectedGameId = availableGames[0]['id'];
          selectedGameName = availableGames[0]['name'];
        }
      } catch (_) {}
      loadingGames = false;
    }

    if (!mounted) return;

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            widget.gameTitle != null
                ? 'Nowy post dla: ${widget.gameTitle}'
                : 'Nowy post',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.gameId == null) ...[
                    const Text(
                      'Wybierz grę:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    if (loadingGames)
                      const LinearProgressIndicator()
                    else if (availableGames.isEmpty)
                      const Text('Brak dostępnych gier do wyboru.')
                    else
                      DropdownButtonFormField<int>(
                        value: selectedGameId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: availableGames.map<DropdownMenuItem<int>>((g) {
                          return DropdownMenuItem<int>(
                            value: g['id'] as int,
                            child: Text(
                              g['name'] as String? ?? 'Gra ${g['id']}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedGameId = val;
                          });
                        },
                      ),
                    const SizedBox(height: 14),
                  ],
                  const Text(
                    'Tytuł:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'Wpisz tytuł posta...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Treść:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Podziel się swoją opinią lub pytaniem...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final content = contentController.text.trim();

                if (title.isEmpty || content.isEmpty || selectedGameId == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Uzupełnij wszystkie pola!')),
                  );
                  return;
                }

                try {
                  await _postService.createPost(
                    title: title,
                    content: content,
                    gameId: selectedGameId!,
                  );
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Błąd dodawania posta: $e')),
                    );
                  }
                }
              },
              child: const Text('Opublikuj'),
            ),
          ],
        ),
      ),
    );

    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post został opublikowany')),
      );
      _currentPage = 1;
      _loadPosts();
    }
  }

  Future<void> _deletePost(int postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usuń post'),
        content: const Text('Czy na pewno chcesz usunąć ten post wraz z komentarzami?'),
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
      await _postService.deletePost(postId);
      if (!mounted) return;
      setState(() {
        _posts.removeWhere((p) => p['id'] == postId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post został usunięty')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się usunąć posta: $e')),
      );
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return raw.length > 10 ? raw.substring(0, 10) : raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.gameTitle != null
        ? 'Posty: ${widget.gameTitle}'
        : 'Posty i dyskusje';

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePostDialog,
        backgroundColor: const Color(0xFF20A894),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('Nowy post'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPosts,
              child: _posts.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        const Icon(
                          Icons.forum_outlined,
                          color: Color(0xFF20A894),
                          size: 52,
                        ),
                        const SizedBox(height: 16),
                        const Center(
                          child: Text(
                            'Brak postów',
                            style: TextStyle(
                              color: Color(0xFF17283F),
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Center(
                          child: Text(
                            'Bądź pierwszą osobą, która rozpocznie dyskusję!',
                            style: TextStyle(color: Color(0xFF728092)),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
                            itemCount: _posts.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final post = _posts[index] as Map<String, dynamic>;
                              final postId = post['id'] as int;
                              final title = post['title'] as String? ?? 'Bez tytułu';
                              final content = post['content'] as String? ?? '';
                              final username = post['username'] as String? ?? 'Użytkownik';
                              final dateStr = _formatDate(post['created_at'] as String?);

                              return Card(
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PostDetailScreen(post: post),
                                      ),
                                    );
                                    _loadPosts();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE7F4F1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                username,
                                                style: const TextStyle(
                                                  color: Color(0xFF168A83),
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              dateStr,
                                              style: const TextStyle(
                                                color: Color(0xFF728092),
                                                fontSize: 12,
                                              ),
                                            ),
                                            const Spacer(),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline_rounded,
                                                size: 18,
                                                color: Colors.grey,
                                              ),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              tooltip: 'Usuń post',
                                              onPressed: () => _deletePost(postId),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          title,
                                          style: const TextStyle(
                                            color: Color(0xFF17283F),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          content,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF728092),
                                            fontSize: 14,
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const Row(
                                          children: [
                                            Icon(
                                              Icons.mode_comment_outlined,
                                              size: 16,
                                              color: Color(0xFF20A894),
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'Zobacz dyskusję i komentarze',
                                              style: TextStyle(
                                                color: Color(0xFF20A894),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Spacer(),
                                            Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 14,
                                              color: Color(0xFF728092),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (_totalPages > 1)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton.filledTonal(
                                  tooltip: 'Poprzednia strona',
                                  onPressed: _currentPage > 1
                                      ? () {
                                          setState(() => _currentPage--);
                                          _loadPosts();
                                        }
                                      : null,
                                  icon: const Icon(Icons.chevron_left),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 18),
                                  child: Text(
                                    '$_currentPage / $_totalPages',
                                    style: const TextStyle(
                                      color: Color(0xFF17283F),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                IconButton.filledTonal(
                                  tooltip: 'Następna strona',
                                  onPressed: _currentPage < _totalPages
                                      ? () {
                                          setState(() => _currentPage++);
                                          _loadPosts();
                                        }
                                      : null,
                                  icon: const Icon(Icons.chevron_right),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
    );
  }
}

