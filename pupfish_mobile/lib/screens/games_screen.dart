import 'package:flutter/material.dart';
import '../services/game_service.dart';
import './game_details_screen.dart';
import '../widgets/game_cover.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  final _gameService = GameService();
  final _searchController = TextEditingController();

  List<dynamic> _games = [];

  bool _loading = true;

  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    setState(() {
      _loading = true;
    });

    try {
      final data = await _gameService.getGames(
        page: _currentPage,
        search: _searchController.text,
      );

      if (!mounted) return;
      setState(() {
        _games = data['results'] ?? [];

        final count = data['count'] ?? 0;
        const pageSize = 20;

        _totalPages = (count / pageSize).ceil();

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd: $e'),
        ),
      );
    }
  }

  void _search() {
    _currentPage = 1;
    _loadGames();
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
      });

      _loadGames();
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });

      _loadGames();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Odkrywaj gry'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Znajdź swoją następną grę',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF17283F),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: 'Szukaj po nazwie',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      tooltip: 'Szukaj',
                      onPressed: _search,
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _games.isEmpty
                    ? _EmptyGames(onRetry: _loadGames)
                    : RefreshIndicator(
                        onRefresh: _loadGames,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          itemCount: _games.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final game =
                                _games[index] as Map<String, dynamic>;
                            return _GameCard(
                              game: game,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      GameDetailsScreen(game: game),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
          if (!_loading && _games.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Poprzednia strona',
                    onPressed: _currentPage > 1 ? _previousPage : null,
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
                    onPressed:
                        _currentPage < _totalPages ? _nextPage : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game, required this.onTap});

  final Map<String, dynamic> game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rating = game['rating'];
    final ratingLabel = rating == null
        ? 'Brak oceny'
        : 'Ocena ${rating is num ? rating.toStringAsFixed(1) : rating}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              GameCover(url: game['cover_url'] as String?),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game['name'] as String? ?? 'Bez nazwy',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF17283F),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Premiera: ${game['release_date'] ?? 'brak danych'}',
                      style: const TextStyle(color: Color(0xFF728092)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFF2AE43),
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ratingLabel,
                          style: const TextStyle(
                            color: Color(0xFF728092),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF728092)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyGames extends StatelessWidget {
  const _EmptyGames({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 90),
        const Icon(
          Icons.search_off_rounded,
          color: Color(0xFF20A894),
          size: 48,
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'Nie znaleziono gier',
            style: TextStyle(
              color: Color(0xFF17283F),
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Center(
          child: Text(
            'Spróbuj zmienić wyszukiwaną frazę.',
            style: TextStyle(color: Color(0xFF728092)),
          ),
        ),
        Center(
          child: TextButton(
            onPressed: onRetry,
            child: const Text('Pokaż ponownie'),
          ),
        ),
      ],
    );
  }
}