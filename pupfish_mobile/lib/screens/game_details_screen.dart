import 'package:flutter/material.dart';
import '../services/game_service.dart';
import '../widgets/game_cover.dart';


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
              game['name'] as String? ?? 'Bez nazwy',
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
          ],
        ),
      ),
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