import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../providers/note_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/vault_provider.dart';
import 'ai/ai_chat_panel.dart';
import 'editor/note_editor_screen.dart';
import 'graph/knowledge_graph_screen.dart';
import 'sidebar/sidebar_explorer.dart';

/// [Member 4 - T4.2, T4.3] Khung giao diện chính Desktop Shell 3 Cột Resizable.
///
/// Bố cục: [Sidebar (M1)] | [Editor (M2)] | [AI Panel (M3)]
/// AppBar: Tên Vault, toggle Sidebar, nút Graph, nút Dark/Light
/// StatusBar: Đường dẫn note, số từ, trạng thái lưu
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  // ─── Column Widths ───
  double _sidebarWidth = AppConstants.defaultSidebarWidth;
  double _aiPanelWidth = AppConstants.defaultAiPanelWidth;

  // ─── Collapse State ───
  bool _isSidebarCollapsed = false;
  bool _isAiPanelCollapsed = false;

  // ─── Splitter Hover State ───
  bool _isLeftSplitterHovered = false;
  bool _isRightSplitterHovered = false;

  // ─── View State ───
  bool _showGraphView = false;

  // ─── Saved widths before collapse (để khôi phục khi expand lại) ───
  double _savedSidebarWidth = AppConstants.defaultSidebarWidth;
  double _savedAiPanelWidth = AppConstants.defaultAiPanelWidth;

  // ═══════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: _buildAppBar(context, theme, colorScheme),
      body: Column(
        children: [
          // ─── Main Content: 3 cột Resizable ───
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ═══ CỘT 1: SIDEBAR (Member 1) ═══
                if (!_isSidebarCollapsed) ...[
                  SizedBox(
                    width: _sidebarWidth,
                    child: const SidebarExplorer(),
                  ),

                  // ─── Left Splitter (kéo giãn Sidebar ↔ Editor) ───
                  _buildResizableSplitter(
                    isHovered: _isLeftSplitterHovered,
                    onHoverChanged: (h) => setState(() => _isLeftSplitterHovered = h),
                    onDragUpdate: (details) {
                      setState(() {
                        _sidebarWidth = (_sidebarWidth + details.delta.dx).clamp(
                          AppConstants.minSidebarWidth,
                          AppConstants.maxSidebarWidth,
                        );
                      });
                    },
                    colorScheme: colorScheme,
                  ),
                ],

                // ═══ CỘT 2: EDITOR hoặc GRAPH (Member 2 / Member 4) ═══
                Expanded(
                  child: Container(
                    color: colorScheme.surface.withAlpha(40),
                    child: _showGraphView
                        ? const KnowledgeGraphScreen()
                        : NoteEditorScreen(
                            onCreateMissingNote: (title) =>
                                _createMissingNote(context, title),
                          ),
                  ),
                ),

                // ═══ CỘT 3: AI PANEL (Member 3) ═══
                if (!_isAiPanelCollapsed) ...[
                  // ─── Right Splitter (kéo giãn Editor ↔ AI Panel) ───
                  _buildResizableSplitter(
                    isHovered: _isRightSplitterHovered,
                    onHoverChanged: (h) => setState(() => _isRightSplitterHovered = h),
                    onDragUpdate: (details) {
                      setState(() {
                        // Kéo sang trái = AI panel rộng hơn (delta.dx âm)
                        _aiPanelWidth = (_aiPanelWidth - details.delta.dx).clamp(
                          AppConstants.minAiPanelWidth,
                          AppConstants.maxAiPanelWidth,
                        );
                      });
                    },
                    colorScheme: colorScheme,
                  ),

                  SizedBox(
                    width: _aiPanelWidth,
                    child: const AIChatPanel(),
                  ),
                ],
              ],
            ),
          ),

          // ─── STATUS BAR ───
          _buildStatusBar(context, colorScheme),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  APP BAR (T4.3)
  // ═══════════════════════════════════════════
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final vaultProvider = context.watch<VaultProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return AppBar(
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Icon(Icons.psychology, color: colorScheme.primary, size: 22),
      ),
      leadingWidth: 36,
      title: Row(
        children: [
          Text(
            vaultProvider.hasVault
                ? 'FPTU SE KB — ${vaultProvider.rootItem?.name ?? "Vault"}'
                : 'FPTU SE SECOND BRAIN (ARCHITECTURAL TEMPLATE)',
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              AppConstants.appVersion,
              style: TextStyle(
                fontSize: 9,
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Toggle Sidebar
        Tooltip(
          message: _isSidebarCollapsed ? 'Hiện Sidebar' : 'Ẩn Sidebar',
          child: IconButton(
            icon: Icon(
              _isSidebarCollapsed ? Icons.menu_open : Icons.menu,
              size: 18,
            ),
            onPressed: () {
              setState(() {
                if (_isSidebarCollapsed) {
                  _sidebarWidth = _savedSidebarWidth;
                } else {
                  _savedSidebarWidth = _sidebarWidth;
                }
                _isSidebarCollapsed = !_isSidebarCollapsed;
              });
            },
          ),
        ),

        // Toggle AI Panel
        Tooltip(
          message: _isAiPanelCollapsed ? 'Hiện AI Panel' : 'Ẩn AI Panel',
          child: IconButton(
            icon: Icon(
              _isAiPanelCollapsed ? Icons.smart_toy_outlined : Icons.smart_toy,
              size: 18,
            ),
            onPressed: () {
              setState(() {
                if (_isAiPanelCollapsed) {
                  _aiPanelWidth = _savedAiPanelWidth;
                } else {
                  _savedAiPanelWidth = _aiPanelWidth;
                }
                _isAiPanelCollapsed = !_isAiPanelCollapsed;
              });
            },
          ),
        ),

        const SizedBox(width: 4),

        // Toggle Graph View
        Tooltip(
          message: _showGraphView ? 'Về Editor' : 'Knowledge Graph',
          child: IconButton(
            icon: Icon(
              _showGraphView ? Icons.edit_note : Icons.hub_outlined,
              size: 18,
              color: _showGraphView ? colorScheme.primary : null,
            ),
            onPressed: () {
              setState(() => _showGraphView = !_showGraphView);
            },
          ),
        ),

        const SizedBox(width: 4),

        // Dark/Light Toggle
        Tooltip(
          message: themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
          child: IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  RotationTransition(turns: animation, child: child),
              child: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                key: ValueKey(themeProvider.isDarkMode),
                size: 18,
              ),
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ),

        const SizedBox(width: 8),
      ],
    );
  }

  // ═══════════════════════════════════════════
  //  STATUS BAR (T4.3)
  // ═══════════════════════════════════════════
  Widget _buildStatusBar(BuildContext context, ColorScheme colorScheme) {
    final noteProvider = context.watch<NoteProvider>();
    final vaultProvider = context.watch<VaultProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    // Đếm số từ trong note hiện tại
    final wordCount = noteProvider.currentNote?.content
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .length ??
        0;

    final notePath = noteProvider.currentNote?.path ?? 'Chưa mở note';
    final vaultName = vaultProvider.rootItem?.name ?? '—';

    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withAlpha(40),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Vault name
          Icon(Icons.folder_outlined, size: 11, color: colorScheme.onSurface.withAlpha(120)),
          const SizedBox(width: 4),
          Text(
            vaultName,
            style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withAlpha(120)),
          ),

          _statusDivider(colorScheme),

          // Note path
          Icon(Icons.description_outlined, size: 11, color: colorScheme.onSurface.withAlpha(120)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              notePath,
              style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withAlpha(120)),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          _statusDivider(colorScheme),

          // Word count
          Icon(Icons.text_fields, size: 11, color: colorScheme.onSurface.withAlpha(120)),
          const SizedBox(width: 4),
          Text(
            noteProvider.hasNote ? '$wordCount từ' : '—',
            style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withAlpha(120)),
          ),

          _statusDivider(colorScheme),

          // Save status
          Icon(
            noteProvider.hasNote ? Icons.check_circle : Icons.circle_outlined,
            size: 11,
            color: noteProvider.hasNote
                ? colorScheme.primary.withAlpha(180)
                : colorScheme.onSurface.withAlpha(80),
          ),
          const SizedBox(width: 4),
          Text(
            noteProvider.hasNote ? 'Đã lưu' : '—',
            style: TextStyle(
              fontSize: 11,
              color: noteProvider.hasNote
                  ? colorScheme.primary.withAlpha(180)
                  : colorScheme.onSurface.withAlpha(80),
            ),
          ),

          _statusDivider(colorScheme),

          // Theme indicator
          Icon(
            themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            size: 11,
            color: colorScheme.onSurface.withAlpha(100),
          ),
          const SizedBox(width: 4),
          Text(
            themeProvider.isDarkMode ? 'Dark' : 'Light',
            style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withAlpha(100)),
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

  Widget _statusDivider(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 1,
        height: 12,
        color: colorScheme.outline.withAlpha(40),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  RESIZABLE SPLITTER (T4.2)
  // ═══════════════════════════════════════════
  Widget _buildResizableSplitter({
    required bool isHovered,
    required ValueChanged<bool> onHoverChanged,
    required GestureDragUpdateCallback onDragUpdate,
    required ColorScheme colorScheme,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => onHoverChanged(true),
      onExit: (_) => onHoverChanged(false),
      child: GestureDetector(
        onHorizontalDragUpdate: onDragUpdate,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: isHovered ? 4 : 2,
          color: isHovered ? colorScheme.primary : colorScheme.outline.withAlpha(60),
        ),
      ),
    );
  }
}
