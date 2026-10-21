import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'games_screen.dart';
import 'library_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/Devils_Hole_Pupfish.webp',
              width: 34,
              height: 34,
            ),
            const SizedBox(width: 8),
            const Text('pupfish'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Wyloguj się',
            onPressed: () async {
              await AuthService().logout();

              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text(
              'Twoja kolekcja,\ntwoje zasady.',
              style: textTheme.headlineMedium?.copyWith(
                color: const Color(0xFF17283F),
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Odkrywaj gry i miej wszystkie ulubione tytuły w jednym miejscu.',
              style: textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF728092),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1AA890), Color(0xFF168A83)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Czas na nową przygodę?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Znajdź coś dla siebie w katalogu gier.',
                          style: TextStyle(color: Color(0xFFE1F6F1)),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.tonal(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const GamesScreen(),
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF168A83),
                          ),
                          child: const Text('Odkrywaj gry'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Image.asset(
                    'assets/Devils_Hole_Pupfish.webp',
                    width: 86,
                    height: 86,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Twoje miejsce',
              style: textTheme.titleLarge?.copyWith(
                color: const Color(0xFF17283F),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            _DestinationCard(
              icon: Icons.explore_outlined,
              title: 'Katalog gier',
              subtitle: 'Wyszukaj kolejny ulubiony tytuł',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GamesScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _DestinationCard(
              icon: Icons.collections_bookmark_outlined,
              title: 'Moja biblioteka',
              subtitle: 'Wszystkie dodane przez Ciebie gry',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LibraryScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F4F1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: const Color(0xFF168A83)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF17283F),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF728092)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}