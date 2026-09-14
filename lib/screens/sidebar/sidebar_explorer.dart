import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../models/vault_item.dart';
import '../../providers/vault_provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/graph_provider.dart';
import 'context_menu.dart';

/// Sidebar hiển thị cây thư mục (Folder Tree) và các thao tác Filesystem.
/// Phụ trách phát triển chính: Member 1
class SidebarExplorer extends StatelessWidget {
  const SidebarExplorer({super.key});

  @override
  Widget build(BuildContext context) {
    final vaultProvider = context.watch<VaultProvider>();
    final noteProvider = context.watch<NoteProvider>();

    return Material(
      color: AppColors.sidebarBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Sidebar
          _buildSidebarHeader(context, vaultProvider),
          const Divider(height: 1),

          // Nội dung cây thư mục
          Expanded(
            child: vaultProvider.isLoading
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : !vaultProvider.hasVault
                    ? _buildEmptyVaultView(context, vaultProvider)
                    : ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: [
                          _buildVaultItemTree(
                            context,
                            vaultProvider.rootItem!,
                            vaultProvider,
                            noteProvider,
                            level: 0,
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(BuildContext context, VaultProvider vaultProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.folder_copy_outlined, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              vaultProvider.vaultPath != null
                  ? vaultProvider.vaultPath!.split(RegExp(r'[\\/]')).last
                  : 'EXPLORER',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.note_add_outlined, size: 18),
            tooltip: 'Tạo Note mới',
            onPressed: vaultProvider.hasVault
                ? () => _handleCreateNote(context, vaultProvider.vaultPath!)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined, size: 18),
            tooltip: 'Tạo Thư mục mới',
            onPressed: vaultProvider.hasVault
                ? () => _handleCreateFolder(context, vaultProvider.vaultPath!)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            tooltip: 'Làm mới',
            onPressed: vaultProvider.hasVault ? () => vaultProvider.refresh() : null,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyVaultView(BuildContext context, VaultProvider vaultProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open, size: 48, color: AppColors.textDisabled),
            const SizedBox(height: 12),
            const Text(
              'Chưa mở Vault nào',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _handlePickVaultFolder(context, vaultProvider),
              icon: const Icon(Icons.folder_open, size: 16),
              label: const Text('Mở Thư Mục Vault'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaultItemTree(
    BuildContext context,
    VaultItem item,
    VaultProvider vaultProvider,
    NoteProvider noteProvider, {
    required int level,
  }) {
    final isSelected =
        !item.isDirectory && noteProvider.currentNote?.path == item.path;

    if (item.isDirectory) {
      return ExpansionTile(
        key: PageStorageKey(item.path),
        initiallyExpanded: level == 0,
        tilePadding: EdgeInsets.only(left: 12.0 + (level * 14.0), right: 8),
        visualDensity: VisualDensity.compact,
        leading: const Icon(Icons.folder, size: 18, color: Colors.amber),
        title: Text(
          item.name,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _buildItemActionsMenu(context, item, vaultProvider),
        children: item.children
            .map((child) => _buildVaultItemTree(
                  context,
                  child,
                  vaultProvider,
                  noteProvider,
                  level: level + 1,
                ))
            .toList(),
      );
    }

    return Padding(
      padding: EdgeInsets.only(left: 12.0 + (level * 14.0), right: 8, top: 1, bottom: 1),
      child: Material(
        color: isSelected ? AppColors.primary.withAlpha(50) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () {
            noteProvider.openNote(item.path, vaultRoot: vaultProvider.vaultPath);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 16,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildItemActionsMenu(context, item, vaultProvider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemActionsMenu(
    BuildContext context,
    VaultItem item,
    VaultProvider vaultProvider,
  ) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 14, color: AppColors.textDisabled),
      tooltip: 'Thao tác',
      onSelected: (action) async {
        if (action == 'new_note') {
          _handleCreateNote(context, item.path);
        } else if (action == 'new_folder') {
          _handleCreateFolder(context, item.path);
        } else if (action == 'rename') {
          _handleRename(context, item, vaultProvider);
        } else if (action == 'delete') {
          _handleDelete(context, item, vaultProvider);
        }
      },
      itemBuilder: (ctx) => [
        if (item.isDirectory) ...[
          const PopupMenuItem(
            value: 'new_note',
            child: Row(children: [
              Icon(Icons.note_add_outlined, size: 16),
              SizedBox(width: 8),
              Text('Note mới'),
            ]),
          ),
          const PopupMenuItem(
            value: 'new_folder',
            child: Row(children: [
              Icon(Icons.create_new_folder_outlined, size: 16),
              SizedBox(width: 8),
              Text('Folder mới'),
            ]),
          ),
          const PopupMenuDivider(),
        ],
        const PopupMenuItem(
          value: 'rename',
          child: Row(children: [
            Icon(Icons.edit_outlined, size: 16),
            SizedBox(width: 8),
            Text('Đổi tên'),
          ]),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Xóa', style: TextStyle(color: Colors.redAccent)),
          ]),
        ),
      ],
    );
  }

  Future<void> _handlePickVaultFolder(BuildContext context, VaultProvider vaultProvider) async {
    try {
      final selectedDirectory = await FilePicker.getDirectoryPath();
      if (selectedDirectory != null) {
        await vaultProvider.openVault(selectedDirectory);
        if (context.mounted) {
          context.read<GraphProvider>().loadGraph(selectedDirectory);
        }
      } else {
        // Nếu hủy chọn (hoặc đang test mock), mở thư mục mẫu mặc định
        await vaultProvider.openVault('/vault');
        if (context.mounted) {
          context.read<GraphProvider>().loadGraph('/vault');
        }
      }
    } catch (e) {
      // Fallback mở mock path nếu file picker chưa sẵn sàng
      await vaultProvider.openVault('/vault');
      if (context.mounted) {
        context.read<GraphProvider>().loadGraph('/vault');
      }
    }
  }

  Future<void> _handleCreateNote(BuildContext context, String parentPath) async {
    final noteName = await ContextMenuHelper.showInputDialog(
      context: context,
      title: 'Tạo Note Mới',
      hintText: 'Nhập tên ghi chú (ví dụ: Dart_OOP)',
    );
    if (noteName != null && noteName.isNotEmpty && context.mounted) {
      final vaultProvider = context.read<VaultProvider>();
      final newItem = await vaultProvider.createNote(parentPath, noteName);
      if (newItem != null && context.mounted) {
        context.read<NoteProvider>().openNote(newItem.path);
      }
    }
  }

  Future<void> _handleCreateFolder(BuildContext context, String parentPath) async {
    final folderName = await ContextMenuHelper.showInputDialog(
      context: context,
      title: 'Tạo Thư Mục Mới',
      hintText: 'Nhập tên thư mục (ví dụ: PRN231_WebAPI)',
    );
    if (folderName != null && folderName.isNotEmpty && context.mounted) {
      context.read<VaultProvider>().createFolder(parentPath, folderName);
    }
  }

  Future<void> _handleRename(
    BuildContext context,
    VaultItem item,
    VaultProvider vaultProvider,
  ) async {
    final newName = await ContextMenuHelper.showInputDialog(
      context: context,
      title: 'Đổi Tên',
      hintText: 'Nhập tên mới',
      initialValue: item.name,
    );
    if (newName != null && newName.isNotEmpty && newName != item.name) {
      vaultProvider.renameItem(item.path, newName);
    }
  }

  Future<void> _handleDelete(
    BuildContext context,
    VaultItem item,
    VaultProvider vaultProvider,
  ) async {
    final confirmed = await ContextMenuHelper.showConfirmDeleteDialog(
      context: context,
      item: item,
    );
    if (confirmed) {
      vaultProvider.deleteItem(item.path);
    }
  }
}
