import 'package:flutter/material.dart';

class GameCover extends StatelessWidget {
  const GameCover({
    super.key,
    this.url,
    this.width = 72,
    this.height = 96,
    this.borderRadius = 14,
  });

  final String? url;
  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: imageUrl == null || imageUrl.isEmpty
            ? const _CoverPlaceholder()
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _CoverPlaceholder(),
              ),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE7F4F1),
      child: Center(
        child: Icon(
          Icons.videogame_asset_rounded,
          color: Color(0xFF20A894),
          size: 30,
        ),
      ),
    );
  }
}
