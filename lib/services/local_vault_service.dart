import 'dart:io';

import 'package:path/path.dart' as path;

import '../contracts/vault_service.dart';
import '../models/vault_item.dart';

/// Triển khai VaultService trực tiếp trên hệ thống tệp cục bộ.
class LocalVaultService implements VaultService {
  static final _invalidNameCharacters = RegExp(r'[\\/:*?"<>|]');

  @override
  Future<VaultItem> loadVaultHierarchy(String rootPath) async {
    final root = Directory(rootPath);
    if (!await root.exists()) {
      throw FileSystemException('Vault folder does not exist.', rootPath);
    }
    return _readDirectory(root);
  }

  Future<VaultItem> _readDirectory(Directory directory) async {
    final children = <VaultItem>[];
    await for (final entity in directory.list(followLinks: false)) {
      final name = path.basename(entity.path);
      // Vault chỉ hiển thị thư mục thường và các ghi chú Markdown.
      if (name.startsWith('.') || entity is Link) {
        continue;
      }
      if (entity is Directory) {
        children.add(await _readDirectory(entity));
      } else if (entity is File &&
          path.extension(name).toLowerCase() == '.md') {
        children.add(
          VaultItem(name: name, path: entity.path, isDirectory: false),
        );
      }
    }
    children.sort((a, b) {
      if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return VaultItem(
      name: path.basename(path.normalize(directory.path)),
      path: directory.path,
      isDirectory: true,
      children: children,
    );
  }

  @override
  Future<VaultItem> createFolder(String parentPath, String folderName) async {
    final name = _validateName(folderName, itemType: 'Folder');
    final parent = await _requireDirectory(parentPath);
    final folder = Directory(path.join(parent.path, name));
    if (await folder.exists() || await File(folder.path).exists()) {
      throw FileSystemException(
        'An item with this name already exists.',
        folder.path,
      );
    }
    await folder.create();
    return VaultItem(name: name, path: folder.path, isDirectory: true);
  }

  @override
  Future<VaultItem> createNote(String parentPath, String noteName) async {
    var name = _validateName(noteName, itemType: 'Note');
    if (!name.toLowerCase().endsWith('.md')) name = '$name.md';
    if (name.toLowerCase() == '.md') {
      throw ArgumentError.value(
        noteName,
        'noteName',
        'Note name cannot be empty.',
      );
    }
    final parent = await _requireDirectory(parentPath);
    final file = File(path.join(parent.path, name));
    if (await file.exists() || await Directory(file.path).exists()) {
      throw FileSystemException(
        'An item with this name already exists.',
        file.path,
      );
    }
    await file.writeAsString('# ${path.basenameWithoutExtension(name)}\n');
    return VaultItem(name: name, path: file.path, isDirectory: false);
  }

  @override
  Future<void> renameItem(String oldPath, String newName) async {
    final name = _validateName(newName, itemType: 'Item');
    final entityType = await FileSystemEntity.type(oldPath, followLinks: false);
    if (entityType == FileSystemEntityType.notFound) {
      throw FileSystemException('Item does not exist.', oldPath);
    }
    final currentName = path.basename(oldPath);
    final finalName =
        entityType == FileSystemEntityType.file &&
            path.extension(currentName).toLowerCase() == '.md' &&
            !name.toLowerCase().endsWith('.md')
        ? '$name.md'
        : name;
    final newPath = path.join(path.dirname(oldPath), finalName);
    if (path.equals(path.normalize(oldPath), path.normalize(newPath))) return;
    if (await FileSystemEntity.type(newPath, followLinks: false) !=
        FileSystemEntityType.notFound) {
      throw FileSystemException(
        'An item with this name already exists.',
        newPath,
      );
    }
    if (entityType == FileSystemEntityType.directory) {
      await Directory(oldPath).rename(newPath);
    } else {
      await File(oldPath).rename(newPath);
    }
  }

  @override
  Future<void> deleteItem(String targetPath) async {
    final entityType = await FileSystemEntity.type(
      targetPath,
      followLinks: false,
    );
    if (entityType == FileSystemEntityType.notFound) {
      throw FileSystemException('Item does not exist.', targetPath);
    }
    if (entityType == FileSystemEntityType.directory) {
      await Directory(targetPath).delete(recursive: true);
    } else {
      await File(targetPath).delete();
    }
  }

  Future<Directory> _requireDirectory(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      throw FileSystemException('Parent folder does not exist.', directoryPath);
    }
    return directory;
  }

  String _validateName(String value, {required String itemType}) {
    final name = value.trim();
    if (name.isEmpty ||
        name == '.' ||
        name == '..' ||
        _invalidNameCharacters.hasMatch(name)) {
      throw ArgumentError.value(value, 'name', '$itemType name is invalid.');
    }
    return name;
  }
}
