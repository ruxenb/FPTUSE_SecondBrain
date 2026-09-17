import 'package:flutter/foundation.dart';

import '../contracts/vault_service.dart';
import '../models/vault_item.dart';

/// Quản lý trạng thái cây thư mục Vault.
/// [MEMBER 1] sẽ hoàn thiện logic tại đây theo Task T1.3.
class VaultProvider extends ChangeNotifier {
  final VaultService vaultService;

  VaultProvider({required this.vaultService});

  String? _vaultPath;
  VaultItem? _rootItem;
  bool _isLoading = false;
  String? _errorMessage;

  String? get vaultPath => _vaultPath;
  VaultItem? get rootItem => _rootItem;
  bool get isLoading => _isLoading;
  bool get hasVault => _vaultPath != null && _rootItem != null;
  String? get errorMessage => _errorMessage;

  /// Mở và quét một Vault mới.
  Future<void> openVault(String path) async {
    _isLoading = true;
    notifyListeners();

    try {
      final rootItem = await vaultService.loadVaultHierarchy(path);
      _vaultPath = rootItem.path;
      _rootItem = rootItem;
      _errorMessage = null;
    } catch (error) {
      _errorMessage = 'Không thể mở Vault: $error';
      debugPrint('Error loading vault: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createFolder(String parentPath, String name) =>
      _mutate(() => vaultService.createFolder(parentPath, name));

  Future<VaultItem?> createNote(String parentPath, String name) async {
    final vaultPath = _vaultPath;
    if (vaultPath == null) {
      _errorMessage = 'Không thể cập nhật Vault: Chưa có Vault nào được mở.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final createdItem = await vaultService.createNote(parentPath, name);
      _rootItem = await vaultService.loadVaultHierarchy(vaultPath);
      return createdItem;
    } catch (error) {
      _errorMessage = 'Không thể cập nhật Vault: $error';
      debugPrint('Error creating note: $error');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> renameItem(String oldPath, String newName) =>
      _mutate(() => vaultService.renameItem(oldPath, newName));

  Future<bool> deleteItem(String targetPath) =>
      _mutate(() => vaultService.deleteItem(targetPath));

  Future<bool> _mutate(Future<void> Function() operation) async {
    final vaultPath = _vaultPath;
    if (vaultPath == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await operation();
      _rootItem = await vaultService.loadVaultHierarchy(vaultPath);
      return true;
    } catch (error) {
      _errorMessage = 'Không thể cập nhật Vault: $error';
      debugPrint('Error changing vault: $error');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
