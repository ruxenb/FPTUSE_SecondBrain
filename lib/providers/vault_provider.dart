import 'package:flutter/foundation.dart';
import '../contracts/vault_service.dart';
import '../models/vault_item.dart';

/// Quản lý trạng thái cây thư mục và đường dẫn Vault đang chọn.
/// Phụ trách: Member 1
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
  String? get errorMessage => _errorMessage;
  bool get hasVault => _vaultPath != null && _rootItem != null;

  /// Nạp thư mục Vault
  Future<void> openVault(String path) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _vaultPath = path;
      _rootItem = await vaultService.loadVaultHierarchy(path);
    } catch (e) {
      _errorMessage = 'Không thể tải thư mục: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tạo thư mục con
  Future<void> createFolder(String parentPath, String folderName) async {
    try {
      await vaultService.createFolder(parentPath, folderName);
      if (_vaultPath != null) {
        _rootItem = await vaultService.loadVaultHierarchy(_vaultPath!);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Lỗi tạo thư mục: $e';
      notifyListeners();
    }
  }

  /// Tạo Note mới (.md)
  Future<VaultItem?> createNote(String parentPath, String noteName) async {
    try {
      final newItem = await vaultService.createNote(parentPath, noteName);
      if (_vaultPath != null) {
        _rootItem = await vaultService.loadVaultHierarchy(_vaultPath!);
        notifyListeners();
      }
      return newItem;
    } catch (e) {
      _errorMessage = 'Lỗi tạo note: $e';
      notifyListeners();
      return null;
    }
  }

  /// Đổi tên tệp tin / thư mục
  Future<void> renameItem(String oldPath, String newName) async {
    try {
      await vaultService.renameItem(oldPath, newName);
      if (_vaultPath != null) {
        _rootItem = await vaultService.loadVaultHierarchy(_vaultPath!);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Lỗi đổi tên: $e';
      notifyListeners();
    }
  }

  /// Xóa tệp tin / thư mục
  Future<void> deleteItem(String targetPath) async {
    try {
      await vaultService.deleteItem(targetPath);
      if (_vaultPath != null) {
        _rootItem = await vaultService.loadVaultHierarchy(_vaultPath!);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Lỗi xóa mục: $e';
      notifyListeners();
    }
  }

  /// Làm mới lại cây thư mục
  Future<void> refresh() async {
    if (_vaultPath != null) {
      await openVault(_vaultPath!);
    }
  }
}
