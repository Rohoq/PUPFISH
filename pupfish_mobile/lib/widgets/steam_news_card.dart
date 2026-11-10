import 'package:flutter/material.dart';

import '../services/steam_news_content.dart';

class SteamNewsCard extends StatelessWidget {
  const SteamNewsCard({super.key, required this.news, this.onTap});

  final Map<String, dynamic> news;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title = news['title'] as String? ?? '';
    final contents = SteamNewsContent.toPlainText(
      news['contents'] as String? ?? '',
    );
    final author = news['author'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF17283F),
                      ),
                    ),
                  ),
                  if (onTap != null)
                    const Tooltip(
                      message: 'Czytaj w aplikacji',
                      child: Icon(
                        Icons.article_outlined,
                        size: 18,
                        color: Color(0xFF168A83),
                      ),
                    ),
                ],
              ),
              if (author.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  author,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
              if (contents.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  contents,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
