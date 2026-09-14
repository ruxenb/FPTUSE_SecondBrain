import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../providers/vault_provider.dart';
import '../providers/note_provider.dart';
import '../providers/graph_provider.dart';

import 'sidebar/sidebar_explorer.dart';
import 'editor/note_editor_screen.dart';
import 'ai/ai_chat_panel.dart';
import 'graph/knowledge_graph_screen.dart';

enum CenterViewMode { editor, graph }

/// Giao diện Shell 3 cột chính của ứng dụng Desktop.
/// Phụ trách: Member 4
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  double _sidebarWidth = AppConstants.defaultSidebarWidth;
  double _rightPanelWidth = AppConstants.defaultAiPanelWidth;
  bool _isSidebarVisible = true;
  bool _isRightPanelVisible = true;
  CenterViewMode _centerMode = CenterViewMode.editor;

  @override
  void initState() {
    super.initState();
    // Tự động tải dữ liệu Mock ngay khi mở app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vaultProvider = context.read<VaultProvider>();
      final noteProvider = context.read<NoteProvider>();
      final graphProvider = context.read<GraphProvider>();

      vaultProvider.openVault('/vault').then((_) {
        // Mở sẵn note đầu tiên mẫu
        noteProvider.openNote(
          '/vault/PRM393_Mobile_Programming/Flutter_Architecture.md',
          vaultRoot: '/vault',
        );
        // Tải đồ thị ban đầu
        graphProvider.loadGraph('/vault');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final vaultProvider = context.watch<VaultProvider>();
    final noteProvider = context.watch<NoteProvider>();

    return Scaffold(
      appBar: _buildAppBar(context, vaultProvider),
      body: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // CỘT 1: SIDEBAR EXPLORER (MEMBER 1)
                if (_isSidebarVisible) ...[
                  SizedBox(
                    width: _sidebarWidth,
                    child: const SidebarExplorer(),
                  ),
                  _buildResizeHandle(
                    onDrag: (delta) {
                      setState(() {
                        _sidebarWidth = (_sidebarWidth + delta).clamp(
                          AppConstants.minSidebarWidth,
                          AppConstants.maxSidebarWidth,
                        );
                      });
                    },
                  ),
                ],

                // CỘT 2: KHUNG CHÍNH (EDITOR HOẶC GRAPH) (MEMBER 2 & 4)
                Expanded(
                  child: _centerMode == CenterViewMode.editor
                      ? const NoteEditorScreen()
                      : const KnowledgeGraphScreen(),
                ),

                // CỘT 3: AI ASSISTANT PANEL (MEMBER 3)
                if (_isRightPanelVisible) ...[
                  _buildResizeHandle(
                    onDrag: (delta) {
                      setState(() {
                        _rightPanelWidth = (_rightPanelWidth - delta).clamp(
                          AppConstants.minAiPanelWidth,
                          AppConstants.maxAiPanelWidth,
                        );
                      });
                    },
                  ),
                  SizedBox(
                    width: _rightPanelWidth,
                    child: const AIChatPanel(),
                  ),
                ],
              ],
            ),
          ),

          // THANH TRẠNG THÁI STATUS BAR DƯỚI CÙNG
          _buildStatusBar(noteProvider),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, VaultProvider vaultProvider) {
    return AppBar(
      leading: IconButton(
        icon: Icon(_isSidebarVisible ? Icons.menu_open : Icons.menu),
        tooltip: 'Ẩn/Hiện Sidebar',
        onPressed: () => setState(() => _isSidebarVisible = !_isSidebarVisible),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(50),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.primary.withAlpha(100)),
            ),
            child: const Text(
              'FPTU SE BRAIN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            vaultProvider.vaultPath ?? 'Chưa chọn Vault',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
      actions: [
        // Chuyển đổi giữa Editor và Knowledge Graph
        IconButton(
          icon: Icon(
            _centerMode == CenterViewMode.graph ? Icons.edit_note : Icons.hub_outlined,
            color: _centerMode == CenterViewMode.graph ? AppColors.secondary : AppColors.textSecondary,
          ),
          tooltip: _centerMode == CenterViewMode.graph
              ? 'Chuyển sang Editor'
              : 'Mở Knowledge Graph',
          onPressed: () {
            setState(() {
              _centerMode = _centerMode == CenterViewMode.editor
                  ? CenterViewMode.graph
                  : CenterViewMode.editor;
            });
          },
        ),

        // Ẩn/Hiện Panel AI
        IconButton(
          icon: Icon(
            Icons.auto_awesome,
            color: _isRightPanelVisible ? AppColors.secondary : AppColors.textDisabled,
          ),
          tooltip: 'Ẩn/Hiện AI Assistant',
          onPressed: () => setState(() => _isRightPanelVisible = !_isRightPanelVisible),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildResizeHandle({required ValueChanged<double> onDrag}) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (details) => onDrag(details.delta.dx),
        child: Container(
          width: 4,
          color: AppColors.border,
        ),
      ),
    );
  }

  Widget _buildStatusBar(NoteProvider noteProvider) {
    final note = noteProvider.currentNote;
    final wordCount = note != null
        ? note.content.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length
        : 0;

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: AppColors.sidebarBackground,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Icons.laptop_chromebook, size: 12, color: AppColors.textDisabled),
            const SizedBox(width: 6),
            const Text(
              'Flutter Desktop MVP',
              style: TextStyle(fontSize: 11, color: AppColors.textDisabled),
            ),
            const SizedBox(width: 24),
            if (note != null) ...[
              Text(
                'Từ: $wordCount | Ký tự: ${note.content.length}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 16),
              Text(
                'Liên kết: ${note.outgoingLinks.length} | Backlinks: ${note.backlinks.length}',
                style: const TextStyle(fontSize: 11, color: AppColors.wikilink),
              ),
              const SizedBox(width: 16),
            ],
            const Text(
              'PRM393 - FPT University',
              style: TextStyle(fontSize: 11, color: AppColors.textDisabled),
            ),
          ],
        ),
      ),
    );
  }
}
