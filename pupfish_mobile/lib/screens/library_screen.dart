import 'package:flutter/material.dart';
import '../services/game_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _gameService = GameService();

  List<dynamic> _games = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  Future<void> _loadLibrary() async {
    setState(() {
      _loading = true;
    });

    try {
      final games = await _gameService.getMyLibrary();

      setState(() {
        _games = games;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moja biblioteka'),
      ),

      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _games.isEmpty
              ? const Center(
                  child: Text('Twoja biblioteka jest pusta'),
                )
              : RefreshIndicator(
                  onRefresh: _loadLibrary,
                  child: ListView.builder(
                    itemCount: _games.length,
                    itemBuilder: (context, index) {
                      final game = _games[index];

                      return ListTile(
                        leading: const Icon(
                          Icons.videogame_asset,
                        ),

                        title: Text(
                          game['game_name'] ?? 'Brak nazwy',
                        ),

                        subtitle: Text(
                          game['game_release_date'] ?? '',
                        ),

                        trailing: Text(
                          game['state'] ?? '',
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}