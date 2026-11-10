import 'package:flutter/material.dart';
import '../services/game_service.dart';
import '../widgets/game_cover.dart';
import 'posts_screen.dart';

class GameDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> game;

  const GameDetailsScreen({
    super.key,
    required this.game,
  });

  @override
  State<GameDetailsScreen> createState() => _GameDetailsScreenState();
}

class _GameDetailsScreenState extends State<GameDetailsScreen> {
  final _gameService = GameService();
  final _commentController = TextEditingController();

  bool _adding = false;
  bool _submittingComment = false;

  // News
  List<dynamic> _news = [];
  bool _newsLoading = true;
  String? _newsError;

  // Platforms
  List<dynamic> _platforms = [];
  bool _platformsLoading = true;

  // Comments
  List<dynamic> _comments = [];
  bool _commentsLoading = true;

  int get _gameId => widget.game['id'] as int;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    _loadNews();
    _loadPlatforms();
    _loadComments();
  }

  Future<void> _loadNews() async {
    try {
      final news = await _gameService.getGameNews(_gameId);
      if (!mounted) return;
      setState(() {
        _news = news;
        _newsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _newsError = e.toString();
        _newsLoading = false;
      });
    }
  }

  Future<void> _loadPlatforms() async {
    try {
      final platforms = await _gameService.getGamePlatforms(gameId: _gameId);
      if (!mounted) return;
      setState(() {
        _platforms = platforms;
        _platformsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _platformsLoading = false);
    }
  }

  Future<void> _loadComments() async {
    try {
      final comments = await _gameService.getGameComments(_gameId);
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _commentsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _commentsLoading = false);
    }
  }

  Future<void> _addToLibrary() async {
    setState(() => _adding = true);

    try {
      await _gameService.addToLibrary(_gameId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gra została dodana do biblioteki')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd: $e')),
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _submittingComment = true);

    try {
      await _gameService.addGameComment(gameId: _gameId, comment: text);
      _commentController.clear();
      await _loadComments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd dodawania komentarza: $e')),
      );
    } finally {
      if (mounted) setState(() => _submittingComment = false);
    }
  }

  Future<void> _deleteComment(int commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usuń komentarz'),
        content: const Text('Czy na pewno chcesz usunąć swój komentarz?'),
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
      await _gameService.deleteGameComment(commentId);
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
    final game = widget.game;
    final gameTitle = game['name'] as String? ?? 'Gra';

    return Scaffold(
      appBar: AppBar(
        title: Text(gameTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Center(
              child: GameCover(
                url: game['cover_url'] as String?,
                width: 190,
                height: 250,
                borderRadius: 22,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              gameTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF17283F),
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _GameInfoRow(
                      icon: Icons.calendar_month_outlined,
                      label: 'Data premiery',
                      value: game['release_date']?.toString() ?? 'Brak danych',
                    ),
                    const Divider(height: 24),
                    _GameInfoRow(
                      icon: Icons.star_outline_rounded,
                      label: 'Ocena',
                      value: game['rating']?.toString() ?? 'Brak danych',
                    ),
                  ],
                ),
              ),
            ),

            // Platformy
            const SizedBox(height: 16),
            _buildPlatformsSection(),

            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _adding ? null : _addToLibrary,
              icon: _adding
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_rounded),
              label: Text(
                _adding ? 'Dodawanie...' : 'Dodaj do biblioteki',
              ),
            ),

            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostsScreen(
                      gameId: _gameId,
                      gameTitle: gameTitle,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.forum_outlined),
              label: const Text('Dyskusje i posty o tej grze'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 50),
                foregroundColor: const Color(0xFF168A83),
                side: const BorderSide(color: Color(0xFF168A83)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            // Komentarze do gry
            const SizedBox(height: 28),
            Text(
              'Komentarze społeczności (${_comments.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF17283F),
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            _buildCommentsSection(),

            // Newsy
            const SizedBox(height: 28),
            Text(
              'Aktualności ze Steam',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF17283F),
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            _buildNewsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformsSection() {
    if (_platformsLoading) {
      return const SizedBox(
        height: 24,
        child: Center(child: LinearProgressIndicator()),
      );
    }

    if (_platforms.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dostępne platformy:',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: Color(0xFF728092),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _platforms.map<Widget>((gp) {
            final name = gp['platform_name'] as String? ?? 'Platforma';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F4F1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.sports_esports_rounded,
                    size: 14,
                    color: Color(0xFF168A83),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Color(0xFF168A83),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Napisz komentarz do gry...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _addComment(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _submittingComment ? null : _addComment,
                  icon: _submittingComment
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
        ),
        const SizedBox(height: 10),
        if (_commentsLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_comments.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Brak komentarzy. Bądź pierwszą osobą, która skomentuje tę grę!',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          )
        else
          ..._comments.map<Widget>((c) {
            final commentId = c['id'] as int;
            final user = c['username'] as String? ?? 'Użytkownik';
            final text = c['comment'] as String? ?? '';
            final date = _formatDate(c['created_at'] as String?);

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          user,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF17283F),
                            fontSize: 13,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              date,
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
                              onPressed: () => _deleteComment(commentId),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      text,
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
    );
  }

  Widget _buildNewsSection() {
    if (_newsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_newsError != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Nie udało się załadować newsów.',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    if (_news.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Brak newsów dla tej gry (brak powiązanego Steam ID).',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Column(
      children: _news.map<Widget>((item) {
        final title = item['title'] as String? ?? '';
        final contents = item['contents'] as String? ?? '';
        final author = item['author'] as String? ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF17283F),
                  ),
                ),
                if (author.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    author,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
                if (contents.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    contents,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _GameInfoRow extends StatelessWidget {
  const _GameInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF20A894)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(color: Color(0xFF728092))),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF17283F),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
