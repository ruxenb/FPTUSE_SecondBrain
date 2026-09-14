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

  String? get vaultPath => _vaultPath;
  VaultItem? get rootItem => _rootItem;
  bool get isLoading => _isLoading;
  bool get hasVault => _vaultPath != null && _rootItem != null;

  // TODO: [Member 1] Hiện thực hàm mở Vault
  Future<void> openVault(String path) async {
    _isLoading = true;
    notifyListeners();

    try {
      _vaultPath = path;
      _rootItem = await vaultService.loadVaultHierarchy(path);
    } catch (e) {
      debugPrint('Error loading vault: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // TODO: [Member 1] Thêm các hàm createFolder, createNote, renameItem, deleteItem...
}
