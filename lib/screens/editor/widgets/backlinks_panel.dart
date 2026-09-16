import 'package:flutter/material.dart';

class BacklinksPanel extends StatelessWidget {
  final List<String> backlinks;
  final ValueChanged<String> onOpenBacklink;

  const BacklinksPanel({
    required this.backlinks,
    required this.onOpenBacklink,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Backlinks',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: backlinks.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No backlinks yet',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: backlinks.length,
                    itemBuilder: (context, index) {
                      final title = backlinks[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.link, size: 16),
                        title: Text(title, overflow: TextOverflow.ellipsis),
                        onTap: () => onOpenBacklink(title),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
