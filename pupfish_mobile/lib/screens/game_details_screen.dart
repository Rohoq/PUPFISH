import 'package:flutter/material.dart';
import '../services/game_service.dart';


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

  bool _adding = false;

  Future<void> _addToLibrary() async {
    setState(() {
      _adding = true;
    });

    try {
      await _gameService.addToLibrary(widget.game['id']);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gra została dodana do biblioteki'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _adding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          game['name'] ?? 'Gra',
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              game['name'] ?? 'Brak nazwy',
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            const SizedBox(height: 16),

            Text(
              'Data premiery: ${game['release_date'] ?? 'Brak danych'}',
            ),

            const SizedBox(height: 8),

            Text(
              'Ocena: ${game['rating'] ?? 'Brak danych'}',
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _adding ? null : _addToLibrary,
                icon: const Icon(Icons.add),
                label: Text(
                  _adding
                      ? 'Dodawanie...'
                      : 'Dodaj do biblioteki',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}