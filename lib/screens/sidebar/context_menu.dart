import 'package:flutter/material.dart';
import '../../models/vault_item.dart';

/// Hộp thoại hỗ trợ tạo File / Folder và đổi tên
/// Phụ trách: Member 1
class ContextMenuHelper {
  static Future<String?> showInputDialog({
    required BuildContext context,
    required String title,
    required String hintText,
    String initialValue = '',
  }) async {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title, style: const TextStyle(fontSize: 16)),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: hintText),
            onSubmitted: (val) => Navigator.of(ctx).pop(val.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }

  static Future<bool> showConfirmDeleteDialog({
    required BuildContext context,
    required VaultItem item,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Xác nhận xóa', style: TextStyle(fontSize: 16)),
          content: Text(
            'Bạn có chắc chắn muốn xóa ${item.isDirectory ? "thư mục" : "ghi chú"} "${item.name}" không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
