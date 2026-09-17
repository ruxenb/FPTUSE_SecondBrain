import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../providers/note_provider.dart';
import '../providers/vault_provider.dart';
import 'ai/ai_chat_panel.dart';
import 'editor/note_editor_screen.dart';
import 'sidebar/sidebar_explorer.dart';

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
                const SnackBar(
                  content: Text(
                    'Khu vực Task T4.5: Knowledge Graph của Member 4',
                  ),
                ),
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
                  child: const SidebarExplorer(),
                ),

                const VerticalDivider(width: 1),

                // CỘT 2: MEMBER 2 - NOTE EDITOR & MARKDOWN
                Expanded(
                  child: Container(
                    color: AppColors.background,
                    child: NoteEditorScreen(
                      onCreateMissingNote: (title) =>
                          _createMissingNote(context, title),
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
                Icon(
                  Icons.desktop_windows,
                  size: 12,
                  color: AppColors.textDisabled,
                ),
                SizedBox(width: 6),
                Text(
                  'Task T4.3: Status Bar & Layout Shell - Member 4',
                  style: TextStyle(fontSize: 11, color: AppColors.textDisabled),
                ),
                Spacer(),
                Text(
                  'PRM393 - Fall 2026',
                  style: TextStyle(fontSize: 11, color: AppColors.textDisabled),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _createMissingNote(BuildContext context, String title) async {
    final noteProvider = context.read<NoteProvider>();
    final currentPath = noteProvider.currentNote?.path;
    final parentPath = currentPath == null
        ? noteProvider.vaultRootPath
        : path.dirname(currentPath);
    if (parentPath == null) {
      return null;
    }

    final createdItem = await context.read<VaultProvider>().createNote(
      parentPath,
      title,
    );
    return createdItem?.path;
  }
}
