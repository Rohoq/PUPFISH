import 'package:flutter/material.dart';
import '../services/game_service.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});
  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  final _gameService = GameService();
  List<dynamic> _games = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  void _loadGames() async {
    final games = await _gameService.getGames();
    setState(() {
      _games = games;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gry')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _games.isEmpty
              ? const Center(child: Text('Brak gier'))
              : ListView.builder(
                  itemCount: _games.length,
                  itemBuilder: (context, index) {
                    final game = _games[index];
                    return ListTile(
                      title: Text(game['name']),
                      subtitle: Text(game['release_date'] ?? ''),
                    );
                  },
                ),
    );
  }
}