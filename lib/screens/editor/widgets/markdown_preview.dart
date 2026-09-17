import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/utils/wikilink_parser.dart';

class MarkdownPreview extends StatelessWidget {
  final String markdown;
  final ValueChanged<String> onOpenWikiLink;

  const MarkdownPreview({
    required this.markdown,
    required this.onOpenWikiLink,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Markdown(
      data: WikilinkParser.transformForPreview(markdown),
      selectable: true,
      padding: const EdgeInsets.all(20),
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
      ),
      onTapLink: (text, href, title) {
        final uri = href == null ? null : Uri.tryParse(href);
        if (uri?.scheme != 'wikilink') {
          return;
        }

        final targetTitle = Uri.decodeComponent(
          uri!.path.replaceFirst('/', ''),
        );
        if (targetTitle.isNotEmpty) {
          onOpenWikiLink(targetTitle);
        }
      },
    );
  }
}
