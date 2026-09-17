import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../providers/vault_provider.dart';
import '../providers/note_provider.dart';
import 'ai/ai_chat_panel.dart';

/// Khung giao diện chính (Desktop Shell 3 Cột).
/// Được thiết kế dưới dạng Architecture Template với các placeholder để từng thành viên tự code module của mình.
/// Phụ trách chính: Member 4
class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.psychology, color: AppColors.primary),
            SizedBox(width: 8),
            Text('FPTU SE SECOND BRAIN (ARCHITECTURAL TEMPLATE)'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.hub_outlined),
            tooltip: 'Knowledge Graph (Member 4)',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Khu vực Task T4.5: Knowledge Graph của Member 4')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // CỘT 1: MEMBER 1 - SIDEBAR EXPLORER & TREEVIEW (Width: ~260px)
                Container(
                  width: 280,
                  color: AppColors.sidebarBackground,
                  child: _buildMemberPlaceholder(
                    context,
                    memberNumber: 1,
                    memberName: 'Member 1 (Vault & Filesystem)',
                    icon: Icons.folder_copy_outlined,
                    color: Colors.amber,
                    tasks: const [
                      'Task T1.4: UI Sidebar TreeView',
                      'Task T1.5: Context Menu (Tạo, Đổi tên, Xóa)',
                      'Task T1.6: LocalVaultService (dart:io)',
                    ],
                    onAction: () {
                      context.read<VaultProvider>().openVault('/vault');
                    },
                    actionLabel: 'Test MockVaultService',
                  ),
                ),

                const VerticalDivider(width: 1),

                // CỘT 2: MEMBER 2 - NOTE EDITOR & MARKDOWN
                Expanded(
                  child: Container(
                    color: AppColors.background,
                    child: _buildMemberPlaceholder(
                      context,
                      memberNumber: 2,
                      memberName: 'Member 2 (Markdown Editor & Note)',
                      icon: Icons.edit_note_rounded,
                      color: AppColors.secondary,
                      tasks: const [
                        'Task T2.4: UI Note Editor (TextField/Auto-save)',
                        'Task T2.5: Markdown Preview & [[Wikilinks]]',
                        'Task T2.6: Backlinks Panel & LocalNoteRepository',
                      ],
                      onAction: () {
                        context.read<NoteProvider>().openNote('/vault/PRM393/Flutter_Architecture.md');
                      },
                      actionLabel: 'Test MockNoteRepository',
                    ),
                  ),
                ),

                const VerticalDivider(width: 1),

                // CỘT 3: MEMBER 3 - AI ASSISTANT (Width: ~320px)
                const SizedBox(width: 320, child: AIChatPanel()),
              ],
            ),
          ),

          // THANH STATUS BAR CHÂN TRANG (MEMBER 4)
          Container(
            height: 26,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: AppColors.sidebarBackground,
            child: const Row(
              children: [
                Icon(Icons.desktop_windows, size: 12, color: AppColors.textDisabled),
                SizedBox(width: 6),
                Text('Task T4.3: Status Bar & Layout Shell - Member 4', style: TextStyle(fontSize: 11, color: AppColors.textDisabled)),
                Spacer(),
                Text('PRM393 - Fall 2026', style: TextStyle(fontSize: 11, color: AppColors.textDisabled)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberPlaceholder(
    BuildContext context, {
    required int memberNumber,
    required String memberName,
    required IconData icon,
    required Color color,
    required List<String> tasks,
    required VoidCallback onAction,
    required String actionLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withAlpha(40),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            memberName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withAlpha(80),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: tasks
                  .map((task) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.0),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, size: 14, color: color),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(task, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.play_arrow, size: 14),
            label: Text(actionLabel, style: const TextStyle(fontSize: 11)),
            style: ElevatedButton.styleFrom(
              backgroundColor: color.withAlpha(50),
              foregroundColor: Colors.white,
              elevation: 0,
              side: BorderSide(color: color.withAlpha(120)),
            ),
          ),
        ],
      ),
    );
  }
}
