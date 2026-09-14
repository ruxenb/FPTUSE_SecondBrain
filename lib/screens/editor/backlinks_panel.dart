import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/note_provider.dart';
import '../../providers/vault_provider.dart';

/// Panel hiển thị các bài note khác trích dẫn tới bài note hiện tại (Backlinks).
/// Phụ trách: Member 2
class BacklinksPanel extends StatelessWidget {
  const BacklinksPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final noteProvider = context.watch<NoteProvider>();
    final note = noteProvider.currentNote;

    if (note == null) return const SizedBox.shrink();

    final backlinks = note.backlinks;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.link, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'BACKLINKS (${backlinks.length})',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (backlinks.isEmpty)
            const Text(
              'Chưa có bài ghi chép nào khác trích dẫn bài này.',
              style: TextStyle(fontSize: 12, color: AppColors.textDisabled),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: backlinks.map((linkTitle) {
                return ActionChip(
                  avatar: const Icon(Icons.arrow_back, size: 12, color: AppColors.wikilink),
                  label: Text('[[ $linkTitle ]]', style: const TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.surfaceVariant,
                  side: const BorderSide(color: AppColors.border),
                  onPressed: () {
                    final vaultProvider = context.read<VaultProvider>();
                    final targetPath = '${vaultProvider.vaultPath ?? "/vault"}/$linkTitle.md';
                    noteProvider.openNote(targetPath, vaultRoot: vaultProvider.vaultPath);
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
