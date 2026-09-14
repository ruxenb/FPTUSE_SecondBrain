import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/note_provider.dart';
import '../../providers/vault_provider.dart';
import 'backlinks_panel.dart';

enum EditorViewMode { editOnly, previewOnly, splitView }

/// Màn hình soạn thảo Markdown và hiển thị Preview thời gian thực.
/// Phụ trách: Member 2
class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _textController;
  EditorViewMode _viewMode = EditorViewMode.splitView;
  String? _lastLoadedNotePath;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _syncControllerWithNote(String notePath, String content) {
    if (_lastLoadedNotePath != notePath) {
      _lastLoadedNotePath = notePath;
      _textController.text = content;
    }
  }

  @override
  Widget build(BuildContext context) {
    final noteProvider = context.watch<NoteProvider>();
    final currentNote = noteProvider.currentNote;

    if (noteProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (currentNote == null) {
      return _buildEmptyState();
    }

    _syncControllerWithNote(currentNote.path, currentNote.content);

    return Column(
      children: [
        // Thanh công cụ Editor Toolbar
        _buildEditorToolbar(context, noteProvider),
        const Divider(height: 1),

        // Khung soạn thảo / Preview
        Expanded(
          child: _buildEditorBody(context, noteProvider),
        ),

        // Panel Backlinks chân trang
        const BacklinksPanel(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.edit_note_rounded, size: 64, color: AppColors.textDisabled.withAlpha(120)),
          const SizedBox(height: 16),
          const Text(
            'Chọn một bài ghi chép từ Sidebar để bắt đầu',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cú pháp liên kết bài học: [[Tên Note Khác]]',
            style: TextStyle(color: AppColors.textDisabled, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorToolbar(BuildContext context, NoteProvider noteProvider) {
    final note = noteProvider.currentNote!;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Icon(Icons.description, size: 16, color: AppColors.primary.withAlpha(200)),
            const SizedBox(width: 8),
            Text(
              '${note.title}.md',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(width: 16),

            // Trạng thái lưu file
            Row(
              children: [
                if (noteProvider.isSaving) ...[
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 6),
                  const Text('Đang lưu...', style: TextStyle(fontSize: 11, color: AppColors.warning)),
                ] else if (noteProvider.isDirty) ...[
                  const Icon(Icons.circle, size: 8, color: AppColors.warning),
                  const SizedBox(width: 6),
                  const Text('Chưa lưu', style: TextStyle(fontSize: 11, color: AppColors.warning)),
                ] else ...[
                  const Icon(Icons.check_circle_outline, size: 13, color: AppColors.success),
                  const SizedBox(width: 6),
                  const Text('Đã lưu', style: TextStyle(fontSize: 11, color: AppColors.success)),
                ],
              ],
            ),

            const SizedBox(width: 16),

            // Chế độ xem: Edit / Preview / Split
            SegmentedButton<EditorViewMode>(
              segments: const [
                ButtonSegment(
                  value: EditorViewMode.editOnly,
                  icon: Icon(Icons.edit, size: 14),
                  tooltip: 'Chỉ soạn thảo',
                ),
                ButtonSegment(
                  value: EditorViewMode.splitView,
                  icon: Icon(Icons.vertical_split, size: 14),
                  tooltip: 'Chia đôi (Split View)',
                ),
                ButtonSegment(
                  value: EditorViewMode.previewOnly,
                  icon: Icon(Icons.visibility, size: 14),
                  tooltip: 'Xem trước Markdown',
                ),
              ],
              selected: {_viewMode},
              onSelectionChanged: (newVal) {
                setState(() => _viewMode = newVal.first);
              },
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorBody(BuildContext context, NoteProvider noteProvider) {
    if (_viewMode == EditorViewMode.editOnly) {
      return _buildTextEditor(noteProvider);
    } else if (_viewMode == EditorViewMode.previewOnly) {
      return _buildMarkdownPreview(noteProvider.currentNote!.content);
    } else {
      // Split View
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildTextEditor(noteProvider)),
          const VerticalDivider(width: 1),
          Expanded(child: _buildMarkdownPreview(noteProvider.currentNote!.content)),
        ],
      );
    }
  }

  Widget _buildTextEditor(NoteProvider noteProvider) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: TextField(
        controller: _textController,
        maxLines: null,
        expands: true,
        style: const TextStyle(
          fontFamily: 'Consolas',
          fontSize: 14,
          height: 1.6,
          color: AppColors.textPrimary,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintText: 'Nhập nội dung Markdown tại đây...',
          hintStyle: TextStyle(color: AppColors.textDisabled),
          filled: false,
        ),
        onChanged: (text) {
          noteProvider.updateContent(text);
        },
      ),
    );
  }

  Widget _buildMarkdownPreview(String content) {
    // Tiền xử lý biến cú pháp [[Note Name]] thành link Markdown [Note Name](wikilink:Note Name)
    final processedContent = content.replaceAllMapped(
      RegExp(r'\[\[(.*?)\]\]'),
      (match) {
        final title = match.group(1)?.trim() ?? '';
        return '[$title](wikilink:$title)';
      },
    );

    return Container(
      color: AppColors.surfaceVariant.withAlpha(50),
      padding: const EdgeInsets.all(20),
      child: Markdown(
        data: processedContent,
        selectable: true,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
          h1: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          h2: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          h3: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          p: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textPrimary),
          a: const TextStyle(
            color: AppColors.wikilink,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w600,
          ),
          code: const TextStyle(
            backgroundColor: AppColors.surfaceVariant,
            fontFamily: 'Consolas',
            fontSize: 13,
          ),
        ),
        onTapLink: (text, href, title) {
          if (href != null && href.startsWith('wikilink:')) {
            final targetTitle = href.replaceFirst('wikilink:', '');
            _handleWikilinkClick(context, targetTitle);
          }
        },
      ),
    );
  }

  void _handleWikilinkClick(BuildContext context, String targetTitle) {
    final vaultProvider = context.read<VaultProvider>();
    final noteProvider = context.read<NoteProvider>();
    final targetPath = '${vaultProvider.vaultPath ?? "/vault"}/$targetTitle.md';

    // Mở note được liên kết
    noteProvider.openNote(targetPath, vaultRoot: vaultProvider.vaultPath);
  }
}
