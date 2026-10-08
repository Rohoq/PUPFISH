import 'package:flutter/material.dart';
import '../services/game_service.dart';
import './game_details_screen.dart';

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

      setState(() {
        _games = data['results'] ?? [];

        final count = data['count'] ?? 0;
        const pageSize = 20;

        _totalPages = (count / pageSize).ceil();

        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });

      if (!mounted) return;

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
        title: const Text('Gry'),
      ),

      body: Column(
        children: [
          // WYSZUKIWANIE
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Szukaj gry...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),

                const SizedBox(width: 8),

                ElevatedButton(
                  onPressed: _search,
                  child: const Text('Szukaj'),
                ),
              ],
            ),
          ),

          // LISTA GIER
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _games.isEmpty
                    ? const Center(
                        child: Text('Brak gier'),
                      )
                    : ListView.builder(
                        itemCount: _games.length,
                        itemBuilder: (context, index) {
                          final game = _games[index];

                          return ListTile(
                            title: Text(
                              game['name'] ?? 'Brak nazwy',
                            ),
                            subtitle: Text(
                              game['release_date'] ?? '',
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      GameDetailsScreen(
                                    game: game,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),

          // PAGINACJA
          if (!_loading && _games.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed:
                        _currentPage > 1 ? _previousPage : null,
                    child: const Text('←'),
                  ),

                  const SizedBox(width: 20),

                  Text(
                    'Strona $_currentPage / $_totalPages',
                  ),

                  const SizedBox(width: 20),

                  ElevatedButton(
                    onPressed: _currentPage < _totalPages
                        ? _nextPage
                        : null,
                    child: const Text('→'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}