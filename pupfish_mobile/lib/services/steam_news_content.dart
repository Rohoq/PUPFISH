class SteamNewsContent {
  static const _namedEntities = {
    'amp': '&',
    'apos': "'",
    'gt': '>',
    'lt': '<',
    'nbsp': ' ',
    'quot': '"',
  };

  static String toPlainText(String contents) {
    var text = contents
        .replaceAll(r'\', '\n\n')
        .replaceAll(
          RegExp(
            r'\[url=[^\]]*\](.*?)\[/url\]',
            caseSensitive: false,
            dotAll: true,
          ),
          r'$1',
        )
        .replaceAll(
          RegExp(r'\[img\].*?\[/img\]', caseSensitive: false, dotAll: true),
          '\n[Obraz]\n',
        )
        .replaceAll(
          RegExp(r'<img\b[^>]*>', caseSensitive: false),
          '\n[Obraz]\n',
        )
        .replaceAll(
          RegExp(
            r'<br\s*/?>|</(?:p|div|h[1-6]|li|blockquote)>',
            caseSensitive: false,
          ),
          '\n',
        )
        .replaceAll(RegExp(r'<li\b[^>]*>', caseSensitive: false), '\n• ')
        .replaceAll(RegExp(r'\[\*\]', caseSensitive: false), '\n• ')
        .replaceAll(RegExp(r'\[/?(?:list|olist)\]', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(
          RegExp(
            r'\[(?:/?(?:b|i|u|s|strike|h[1-6]|p|quote|list|olist|hr|code|noparse)|\*)[^\]]*\]',
            caseSensitive: false,
          ),
          '',
        );

    text = text.replaceAllMapped(
      RegExp(r'&([a-z]+);', caseSensitive: false),
      (match) =>
          _namedEntities[match.group(1)!.toLowerCase()] ?? match.group(0)!,
    );
    text = text.replaceAllMapped(
      RegExp(r'&#(x[0-9a-f]+|\d+);', caseSensitive: false),
      (match) {
        final value = match.group(1)!;
        final codePoint = value.toLowerCase().startsWith('x')
            ? int.tryParse(value.substring(1), radix: 16)
            : int.tryParse(value);
        return codePoint == null
            ? match.group(0)!
            : String.fromCharCode(codePoint);
      },
    );

    return text
        .replaceAll(RegExp(r'[ \t]+\n'), '\n')
        .replaceAll(RegExp(r'\n[ \t]+'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}
