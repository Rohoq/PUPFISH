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
  final Set<int> _updatingEntries = {};

  List<dynamic> _games = [];
  bool _loading = true;

  static const _statuses = <String, String>{
    'playing': 'W trakcie',
    'completed': 'Ukończona',
    'dropped': 'Porzucona',
  };

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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Błąd: $e')));
    }
  }

  Future<void> _updateEntry(
    Map<String, dynamic> game,
    Map<String, dynamic> changes,
  ) async {
    final entryId = game['id'] as int;
    setState(() => _updatingEntries.add(entryId));

    try {
      await _gameService.updateLibraryEntry(entryId, changes);

      if (!mounted) return;
      setState(() {
        final index = _games.indexWhere(
          (entry) => (entry as Map<String, dynamic>)['id'] == entryId,
        );
        if (index != -1) {
          _games[index] = {...game, ...changes};
        }
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Zmiany zostały zapisane.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się zapisać zmian: $error')),
      );
    } finally {
      if (mounted) setState(() => _updatingEntries.remove(entryId));
    }
  }

  Future<void> _showRatingDialog(Map<String, dynamic> game) async {
    final currentRating = game['rating'];
    int? selectedRating = currentRating is num ? currentRating.toInt() : null;

    final changes = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(game['game_name'] as String? ?? 'Oceń grę'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Twoja ocena (1–10)'),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(10, (index) {
                  final rating = index + 1;
                  return ChoiceChip(
                    label: Text('$rating'),
                    selected: selectedRating == rating,
                    onSelected: (_) =>
                        setDialogState(() => selectedRating = rating),
                  );
                }),
              ),
              TextButton(
                onPressed: () => setDialogState(() => selectedRating = null),
                child: const Text('Usuń ocenę'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, {'rating': selectedRating}),
              child: const Text('Zapisz'),
            ),
          ],
        ),
      ),
    );

    if (changes != null && mounted) {
      await _updateEntry(game, changes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moja biblioteka')),
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
                        final rating = game['rating'];
                        final entryId = game['id'] as int;
                        final isUpdating = _updatingEntries.contains(entryId);
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                GameCover(
                                  url:
                                      game['game_cover_url'] as String? ??
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
                                      const SizedBox(height: 8),
                                      DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _statuses.containsKey(state)
                                              ? state
                                              : 'playing',
                                          isDense: true,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          icon: const Icon(
                                            Icons.expand_more,
                                            size: 18,
                                          ),
                                          style: const TextStyle(
                                            color: Color(0xFF168A83),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          items: _statuses.entries
                                              .map(
                                                (entry) =>
                                                    DropdownMenuItem<String>(
                                                      value: entry.key,
                                                      child: Text(entry.value),
                                                    ),
                                              )
                                              .toList(),
                                          onChanged: isUpdating
                                              ? null
                                              : (value) {
                                                  if (value != null &&
                                                      value != state) {
                                                    _updateEntry(game, {
                                                      'state': value,
                                                    });
                                                  }
                                                },
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            color: Color(0xFFF2AE43),
                                            size: 18,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              rating is num
                                                  ? 'Twoja ocena: ${rating.toInt()}/10'
                                                  : 'Nie oceniono',
                                              style: const TextStyle(
                                                color: Color(0xFF728092),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          if (isUpdating)
                                            const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          else
                                            IconButton(
                                              tooltip: 'Zmień ocenę',
                                              visualDensity:
                                                  VisualDensity.compact,
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              onPressed: () =>
                                                  _showRatingDialog(game),
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                                size: 18,
                                                color: Color(0xFF168A83),
                                              ),
                                            ),
                                        ],
                                      ),
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
