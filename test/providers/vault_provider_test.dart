import 'package:flutter_test/flutter_test.dart';
import 'package:fptu_se_second_brain/contracts/vault_service.dart';
import 'package:fptu_se_second_brain/models/vault_item.dart';
import 'package:fptu_se_second_brain/providers/vault_provider.dart';

void main() {
  late _FakeVaultService service;
  late VaultProvider provider;

  setUp(() {
    service = _FakeVaultService();
    provider = VaultProvider(vaultService: service);
  });

  tearDown(() => provider.dispose());

  test('createNote returns the created item and refreshes the tree', () async {
    await provider.openVault(_FakeVaultService.vaultPath);

    final created = await provider.createNote(
      _FakeVaultService.vaultPath,
      'New Note',
    );

    expect(created?.path, r'C:\vault\New Note.md');
    expect(created?.name, 'New Note.md');
    expect(service.loadCount, 2);
    expect(provider.rootItem?.children.single.path, created?.path);
    expect(provider.isLoading, isFalse);
    expect(provider.errorMessage, isNull);
  });

  test('createNote returns null and exposes an error on failure', () async {
    await provider.openVault(_FakeVaultService.vaultPath);
    service.createError = StateError('disk full');

    final created = await provider.createNote(
      _FakeVaultService.vaultPath,
      'New Note',
    );

    expect(created, isNull);
    expect(provider.errorMessage, contains('disk full'));
    expect(provider.isLoading, isFalse);
    expect(service.loadCount, 1);
  });
}

class _FakeVaultService implements VaultService {
  static const vaultPath = r'C:\vault';

  int loadCount = 0;
  Object? createError;
  VaultItem? createdItem;

  @override
  Future<VaultItem> loadVaultHierarchy(String rootPath) async {
    loadCount++;
    return VaultItem(
      name: 'vault',
      path: vaultPath,
      isDirectory: true,
      children: createdItem == null ? const [] : [createdItem!],
    );
  }

  @override
  Future<VaultItem> createNote(String parentPath, String noteName) async {
    if (createError != null) {
      throw createError!;
    }
    createdItem = VaultItem(
      name: '$noteName.md',
      path: '$parentPath\\$noteName.md',
      isDirectory: false,
    );
    return createdItem!;
  }

  @override
  Future<VaultItem> createFolder(String parentPath, String folderName) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteItem(String targetPath) async =>
      throw UnimplementedError();

  @override
  Future<void> renameItem(String oldPath, String newName) async =>
      throw UnimplementedError();
}
