/// Tiện ích dùng chung để đọc Wiki-link MVP từ Markdown.
///
/// Chỉ hỗ trợ cú pháp [[Note title]]. Alias, heading, block reference và embed
/// không được diễn giải đặc biệt ở giai đoạn này.
class WikilinkParser {
  static final RegExp _pattern = RegExp(r'\[\[([^\[\]]*)\]\]');

  static List<String> extract(String markdownContent) {
    final seenTitles = <String>{};
    final links = <String>[];

    for (final match in _pattern.allMatches(markdownContent)) {
      final title = normalizeTitle(match.group(1) ?? '');
      if (title.isEmpty) {
        continue;
      }

      if (seenTitles.add(title.toLowerCase())) {
        links.add(title);
      }
    }

    return List.unmodifiable(links);
  }

  static String normalizeTitle(String title) => title.trim();

  static bool titlesEqual(String first, String second) {
    return normalizeTitle(first).toLowerCase() ==
        normalizeTitle(second).toLowerCase();
  }

  /// Chuyển Wiki-link sang Markdown link chỉ cho lớp preview.
  /// Nội dung Markdown gốc không bị thay đổi.
  static String transformForPreview(String markdownContent) {
    return markdownContent.replaceAllMapped(_pattern, (match) {
      final title = normalizeTitle(match.group(1) ?? '');
      if (title.isEmpty) {
        return match.group(0)!;
      }
      return '[$title](wikilink:///${Uri.encodeComponent(title)})';
    });
  }
}
