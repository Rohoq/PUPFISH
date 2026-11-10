import 'package:flutter/material.dart';
import '../services/platform_service.dart';

class PlatformsScreen extends StatefulWidget {
  const PlatformsScreen({super.key});

  @override
  State<PlatformsScreen> createState() => _PlatformsScreenState();
}

class _PlatformsScreenState extends State<PlatformsScreen> {
  final _platformService = PlatformService();

  List<dynamic> _allPlatforms = [];
  List<dynamic> _userPlatforms = [];
  bool _loading = true;
  final Set<int> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final results = await Future.wait([
        _platformService.getPlatforms(),
        _platformService.getUserPlatforms(),
      ]);

      if (!mounted) return;
      setState(() {
        _allPlatforms = results[0];
        _userPlatforms = results[1];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd: $e')),
      );
    }
  }

  Set<int> get _userPlatformIds =>
      _userPlatforms.map<int>((up) => up['platform'] as int).toSet();

  Future<void> _addPlatform(int platformId) async {
    setState(() => _processingIds.add(platformId));

    try {
      await _platformService.addUserPlatform(platformId);
      if (!mounted) return;

      // Odśwież platformy użytkownika
      final updated = await _platformService.getUserPlatforms();
      if (!mounted) return;

      setState(() => _userPlatforms = updated);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Platforma została dodana')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd dodawania: $e')),
      );
    } finally {
      if (mounted) setState(() => _processingIds.remove(platformId));
    }
  }

  Future<void> _removePlatform(int entryId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usuń platformę'),
        content: Text('Czy na pewno chcesz usunąć "$name" ze swoich platform?'),
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

    setState(() => _processingIds.add(entryId));

    try {
      await _platformService.removeUserPlatform(entryId);
      if (!mounted) return;

      setState(() {
        _userPlatforms.removeWhere((up) => up['id'] == entryId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usunięto platformę "$name"')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd usuwania: $e')),
      );
    } finally {
      if (mounted) setState(() => _processingIds.remove(entryId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userIds = _userPlatformIds;
    final availablePlatforms = _allPlatforms
        .where((p) => !userIds.contains(p['id']))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Moje platformy')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  Text(
                    'Twoje platformy',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF17283F),
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Platformy, na których grasz',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  if (_userPlatforms.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'Nie dodałeś jeszcze żadnej platformy.\nWybierz z listy poniżej!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _userPlatforms.map<Widget>((up) {
                        final entryId = up['id'] as int;
                        final name =
                            up['platform_name'] as String? ?? 'Platforma';
                        final isProcessing =
                            _processingIds.contains(entryId);

                        return InputChip(
                          label: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF17283F),
                            ),
                          ),
                          deleteIcon: isProcessing
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.close, size: 18),
                          onDeleted: isProcessing
                              ? null
                              : () => _removePlatform(entryId, name),
                          backgroundColor: const Color(0xFFE7F4F1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide.none,
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 28),
                  Text(
                    'Dostępne platformy',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF17283F),
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Dotknij platformy, aby dodać ją do swojego profilu',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  if (availablePlatforms.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'Masz już dodane wszystkie dostępne platformy!',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: availablePlatforms.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final platform =
                            availablePlatforms[index] as Map<String, dynamic>;
                        final pId = platform['id'] as int;
                        final name = platform['name'] as String? ?? '';
                        final isProcessing = _processingIds.contains(pId);

                        return Card(
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE7F4F1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.sports_esports_rounded,
                                color: Color(0xFF168A83),
                                size: 22,
                              ),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF17283F),
                              ),
                            ),
                            trailing: isProcessing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(
                                      Icons.add_circle_outline_rounded,
                                      color: Color(0xFF20A894),
                                    ),
                                    onPressed: () => _addPlatform(pId),
                                  ),
                            onTap:
                                isProcessing ? null : () => _addPlatform(pId),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}

