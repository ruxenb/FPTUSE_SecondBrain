import '../models/vault_item.dart';

/// Interface quản lý cấu trúc cây thư mục trên hệ thống tệp tin cục bộ.
/// Phụ trách: Member 1
abstract class VaultService {
  /// Quét toàn bộ thư mục gốc và trả về cấu trúc cây phân cấp
  Future<VaultItem> loadVaultHierarchy(String rootPath);

  /// Tạo một thư mục con mới bên trong đường dẫn cha
  Future<VaultItem> createFolder(String parentPath, String folderName);

  /// Tạo một file note Markdown mới (.md)
  Future<VaultItem> createNote(String parentPath, String noteName);

  /// Đổi tên file hoặc thư mục
  Future<void> renameItem(String oldPath, String newName);

  /// Xóa file hoặc thư mục khỏi ổ cứng
  Future<void> deleteItem(String targetPath);
}
