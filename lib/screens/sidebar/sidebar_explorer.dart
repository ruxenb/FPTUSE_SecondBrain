import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/vault_item.dart';
import '../../providers/note_provider.dart';
import '../../providers/vault_provider.dart';

/// Sidebar quản lý Vault: chọn thư mục, duyệt Markdown và thao tác file.
class SidebarExplorer extends StatefulWidget {
  const SidebarExplorer({super.key});

  @override
  State<SidebarExplorer> createState() => _SidebarExplorerState();
}

class _SidebarExplorerState extends State<SidebarExplorer> {
  final Set<String> _expandedPaths = {};

  Future<void> _pickVault() async {
    final selectedPath = await FilePicker.getDirectoryPath(
      dialogTitle: 'Chọn thư mục Vault',
    );
    if (!mounted || selectedPath == null) return;
    await context.read<VaultProvider>().openVault(selectedPath);
    if (!mounted) return;
    final vault = context.read<VaultProvider>();
    if (vault.errorMessage != null) {
      _showMessage(vault.errorMessage!);
      return;
    }
    context.read<NoteProvider>().setVaultRootPath(vault.vaultPath);
  }

  Future<void> _createItem(String parentPath, {required bool folder}) async {
    final name = await _askForName(
      title: folder ? 'Tạo thư mục' : 'Tạo note Markdown',
      label: folder ? 'Tên thư mục' : 'Tên note',
    );
    if (name == null || !mounted) return;
    final vault = context.read<VaultProvider>();
    final success = folder
        ? await vault.createFolder(parentPath, name)
        : await vault.createNote(parentPath, name);
    if (!mounted) return;
    if (!success) _showMessage(vault.errorMessage ?? 'Không thể tạo mục mới.');
    if (success && folder) setState(() => _expandedPaths.add(parentPath));
  }

  Future<void> _rename(VaultItem item) async {
    final name = await _askForName(
      title: 'Đổi tên',
      label: item.isDirectory ? 'Tên thư mục' : 'Tên note',
      initialValue: item.isMarkdown
          ? item.name.substring(0, item.name.length - 3)
          : item.name,
    );
    if (name == null || !mounted) return;
    final noteProvider = context.read<NoteProvider>();
    final openedPath = noteProvider.currentNote?.path;
    final affectsOpenNote =
        openedPath != null &&
        (openedPath == item.path ||
            (item.isDirectory && path.isWithin(item.path, openedPath)));
    if (affectsOpenNote) await noteProvider.saveCurrentNote();
    if (!mounted) return;
    final vault = context.read<VaultProvider>();
    final success = await vault.renameItem(item.path, name);
    if (!mounted) return;
    if (!success) {
      _showMessage(vault.errorMessage ?? 'Không thể đổi tên.');
      return;
    }
    if (affectsOpenNote) {
      final renamedName =
          !item.isDirectory &&
              item.isMarkdown &&
              !name.toLowerCase().endsWith('.md')
          ? '$name.md'
          : name;
      final renamedPath = path.join(path.dirname(item.path), renamedName);
      final nextPath = item.isDirectory
          ? path.join(renamedPath, path.relative(openedPath, from: item.path))
          : renamedPath;
      await noteProvider.openNote(nextPath, vaultRoot: vault.vaultPath);
    }
  }

  Future<void> _delete(VaultItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Xóa ${item.isDirectory ? 'thư mục' : 'note'}?'),
        content: Text(
          item.isDirectory
              ? 'Toàn bộ nội dung bên trong “${item.name}” sẽ bị xóa vĩnh viễn.'
              : '“${item.name}” sẽ bị xóa vĩnh viễn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final noteProvider = context.read<NoteProvider>();
    final openedPath = noteProvider.currentNote?.path;
    final affectsOpenNote =
        openedPath != null &&
        (openedPath == item.path ||
            (item.isDirectory && path.isWithin(item.path, openedPath)));
    final vault = context.read<VaultProvider>();
    final success = await vault.deleteItem(item.path);
    if (!mounted) return;
    if (!success) {
      _showMessage(vault.errorMessage ?? 'Không thể xóa.');
      return;
    }
    if (affectsOpenNote) noteProvider.clearCurrentNote();
  }

  Future<String?> _askForName({
    required String title,
    required String label,
    String initialValue = '',
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: label,
            hintText: 'Không dùng \\ / : * ? " < > |',
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result?.trim();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VaultProvider>(
      builder: (context, vault, _) {
        final root = vault.rootItem;
        return Column(
          children: [
            _header(vault),
            const Divider(height: 1),
            Expanded(
              child: root == null
                  ? _emptyState(vault)
                  : Stack(
                      children: [
                        ListView(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          children: [_treeItem(root, depth: 0, isRoot: true)],
                        ),
                        if (vault.isLoading)
                          const LinearProgressIndicator(minHeight: 2),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _header(VaultProvider vault) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
    child: Row(
      children: [
        const Icon(
          Icons.folder_open_outlined,
          size: 18,
          color: AppColors.secondary,
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'EXPLORER',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.8,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Mở Vault',
          icon: const Icon(Icons.folder_open, size: 19),
          onPressed: vault.isLoading ? null : _pickVault,
        ),
        if (vault.hasVault)
          IconButton(
            tooltip: 'Tạo note ở Vault',
            icon: const Icon(Icons.note_add_outlined, size: 19),
            onPressed: vault.isLoading
                ? null
                : () => _createItem(vault.rootItem!.path, folder: false),
          ),
      ],
    ),
  );

  Widget _emptyState(VaultProvider vault) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.folder_off_outlined,
            size: 38,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 12),
          const Text('Chưa có Vault nào được mở', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: vault.isLoading ? null : _pickVault,
            icon: const Icon(Icons.folder_open),
            label: const Text('Mở Vault'),
          ),
          if (vault.errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              vault.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _treeItem(VaultItem item, {required int depth, bool isRoot = false}) {
    final isExpanded = isRoot || _expandedPaths.contains(item.path);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () async {
            if (item.isDirectory) {
              setState(
                () => isExpanded
                    ? _expandedPaths.remove(item.path)
                    : _expandedPaths.add(item.path),
              );
            } else {
              await context.read<NoteProvider>().openNote(item.path);
            }
          },
          onSecondaryTapDown: (details) =>
              _showContextMenu(item, details.globalPosition, isRoot: isRoot),
          child: Padding(
            padding: EdgeInsets.only(
              left: 8.0 + depth * 16,
              right: 6,
              top: 3,
              bottom: 3,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  child: item.isDirectory
                      ? Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_right,
                          size: 18,
                        )
                      : null,
                ),
                Icon(
                  item.isDirectory
                      ? (isExpanded ? Icons.folder_open : Icons.folder_outlined)
                      : Icons.description_outlined,
                  size: 17,
                  color: item.isDirectory
                      ? AppColors.warning
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    item.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (item.isDirectory && isExpanded)
          for (final child in item.children) _treeItem(child, depth: depth + 1),
      ],
    );
  }

  Future<void> _showContextMenu(
    VaultItem item,
    Offset position, {
    required bool isRoot,
  }) async {
    final action = await showMenu<_ExplorerAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        if (item.isDirectory) ...[
          const PopupMenuItem(
            value: _ExplorerAction.newNote,
            child: Text('Tạo note mới'),
          ),
          const PopupMenuItem(
            value: _ExplorerAction.newFolder,
            child: Text('Tạo thư mục mới'),
          ),
        ],
        if (!isRoot) ...[
          const PopupMenuItem(
            value: _ExplorerAction.rename,
            child: Text('Đổi tên'),
          ),
          const PopupMenuItem(
            value: _ExplorerAction.delete,
            child: Text('Xóa'),
          ),
        ],
      ],
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _ExplorerAction.newNote:
        await _createItem(item.path, folder: false);
        return;
      case _ExplorerAction.newFolder:
        await _createItem(item.path, folder: true);
        return;
      case _ExplorerAction.rename:
        await _rename(item);
        return;
      case _ExplorerAction.delete:
        await _delete(item);
        return;
    }
  }
}

enum _ExplorerAction { newNote, newFolder, rename, delete }
