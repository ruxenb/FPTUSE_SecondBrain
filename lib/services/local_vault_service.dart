import 'dart:io';
import 'package:path/path.dart' as p;
import '../contracts/vault_service.dart';
import '../models/vault_item.dart';

/// Triển khai thực tế đọc/ghi hệ thống tệp tin cục bộ qua 'dart:io'.
/// Phụ trách triển khai vào Tuần 2: Member 1
class LocalVaultService implements VaultService {
  @override
  Future<VaultItem> loadVaultHierarchy(String rootPath) async {
    final rootDir = Directory(rootPath);
    if (!await rootDir.exists()) {
      throw FileSystemException('Vault directory does not exist', rootPath);
    }

    final children = <VaultItem>[];
    await for (final entity in rootDir.list(followLinks: false)) {
      final name = p.basename(entity.path);
      // Bỏ qua các file/thư mục ẩn như .git
      if (name.startsWith('.')) continue;

      if (entity is Directory) {
        // Đệ quy tải thư mục con
        final subFolder = await loadVaultHierarchy(entity.path);
        children.add(subFolder);
      } else if (entity is File && name.toLowerCase().endsWith('.md')) {
        children.add(VaultItem(
          name: name,
          path: entity.path,
          isDirectory: false,
        ));
      }
    }

    // Sắp xếp: Thư mục lên trước, tệp tin theo sau
    children.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return VaultItem(
      name: p.basename(rootPath),
      path: rootPath,
      isDirectory: true,
      children: children,
    );
  }

  @override
  Future<VaultItem> createFolder(String parentPath, String folderName) async {
    final newDir = Directory(p.join(parentPath, folderName));
    if (!await newDir.exists()) {
      await newDir.create(recursive: true);
    }
    return VaultItem(
      name: folderName,
      path: newDir.path,
      isDirectory: true,
      children: const [],
    );
  }

  @override
  Future<VaultItem> createNote(String parentPath, String noteName) async {
    final fileName = noteName.toLowerCase().endsWith('.md') ? noteName : '$noteName.md';
    final file = File(p.join(parentPath, fileName));
    if (!await file.exists()) {
      final initialTitle = fileName.replaceAll('.md', '');
      await file.writeAsString('# $initialTitle\n\n');
    }
    return VaultItem(
      name: fileName,
      path: file.path,
      isDirectory: false,
    );
  }

  @override
  Future<void> renameItem(String oldPath, String newName) async {
    final parent = p.dirname(oldPath);
    final targetPath = p.join(parent, newName);
    final type = await FileSystemEntity.type(oldPath);
    if (type == FileSystemEntityType.directory) {
      await Directory(oldPath).rename(targetPath);
    } else if (type == FileSystemEntityType.file) {
      await File(oldPath).rename(targetPath);
    }
  }

  @override
  Future<void> deleteItem(String targetPath) async {
    final type = await FileSystemEntity.type(targetPath);
    if (type == FileSystemEntityType.directory) {
      await Directory(targetPath).delete(recursive: true);
    } else if (type == FileSystemEntityType.file) {
      await File(targetPath).delete();
    }
  }
}
