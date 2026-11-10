import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/steam_news_content.dart';

class SteamNewsDetailScreen extends StatelessWidget {
  const SteamNewsDetailScreen({
    super.key,
    required this.news,
    required this.gameName,
  });

  final Map<String, dynamic> news;
  final String gameName;

  @override
  Widget build(BuildContext context) {
    final title = news['title'] as String? ?? '';
    final author = news['author'] as String? ?? '';
    final contents = SteamNewsContent.toPlainText(
      news['contents'] as String? ?? '',
    );
    final date = news['date'];
    final publishedAt = date is num
        ? DateTime.fromMillisecondsSinceEpoch(
            date.toInt() * 1000,
            isUtc: true,
          ).toLocal()
        : null;
    final articleUri = Uri.tryParse(news['url'] as String? ?? '');
    final showSteamLink = _isSteamArticle(articleUri);

    return Scaffold(
      appBar: AppBar(title: const Text('Aktualność')),
      body: SelectionArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                gameName,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF168A83),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF17283F),
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (author.isNotEmpty || publishedAt != null) ...[
                const SizedBox(height: 12),
                Text(
                  _metadataText(author, publishedAt),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
              const Divider(height: 32),
              if (contents.isEmpty)
                Text(
                  'Brak treści tej aktualności.',
                  style: Theme.of(context).textTheme.bodyLarge,
                )
              else
                Text(
                  contents,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.55,
                    color: const Color(0xFF26364A),
                  ),
                ),
              if (showSteamLink) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => _openOriginal(context, articleUri!),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Otwórz oryginał na Steam'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _isSteamArticle(Uri? uri) {
    if (uri == null || uri.scheme != 'https') return false;
    return const [
      'steampowered.com',
      'steamcommunity.com',
      'akamaihd.net',
    ].any((domain) => uri.host == domain || uri.host.endsWith('.$domain'));
  }

  Future<void> _openOriginal(BuildContext context, Uri uri) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        _showOpenError(context);
      }
    } on PlatformException {
      if (context.mounted) {
        _showOpenError(context);
      }
    }
  }

  void _showOpenError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nie udało się otworzyć artykułu.')),
    );
  }

  String _metadataText(String author, DateTime? publishedAt) {
    final parts = <String>[
      if (author.isNotEmpty) author,
      if (publishedAt != null)
        '${publishedAt.year}-${publishedAt.month.toString().padLeft(2, '0')}-'
            '${publishedAt.day.toString().padLeft(2, '0')} '
            '${publishedAt.hour.toString().padLeft(2, '0')}:'
            '${publishedAt.minute.toString().padLeft(2, '0')}',
    ];
    return parts.join(' · ');
  }
}
