import 'package:flutter/material.dart';
import '../services/game_service.dart';
import '../widgets/game_cover.dart';

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

      if (!mounted) return;
      setState(() {
        _games = games;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moja biblioteka'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadLibrary,
              child: _games.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        const Icon(
                          Icons.collections_bookmark_outlined,
                          color: Color(0xFF20A894),
                          size: 52,
                        ),
                        const SizedBox(height: 16),
                        const Center(
                          child: Text(
                            'Twoja biblioteka jest jeszcze pusta',
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
                            'Dodaj gry, które chcesz mieć pod ręką.',
                            style: TextStyle(color: Color(0xFF728092)),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: _games.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final game = _games[index] as Map<String, dynamic>;
                        final state = game['state'] as String?;
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                GameCover(
                                  url: game['game_cover_url'] as String? ??
                                      game['cover_url'] as String?,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        game['game_name'] as String? ??
                                            'Bez nazwy',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF17283F),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 7),
                                      Text(
                                        'Premiera: ${game['game_release_date'] ?? 'brak danych'}',
                                        style: const TextStyle(
                                          color: Color(0xFF728092),
                                        ),
                                      ),
                                      if (state != null && state.isNotEmpty) ...[
                                        const SizedBox(height: 9),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE7F4F1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            state,
                                            style: const TextStyle(
                                              color: Color(0xFF168A83),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}