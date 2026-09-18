import '../contracts/vault_service.dart';
import '../models/vault_item.dart';

/// Triển khai giả lập dữ liệu cây thư mục môn học SE tại FPTU trong bộ nhớ.
/// Sẵn sàng cho Day 2 để Member 1 và Member 4 test UI Sidebar.
class MockVaultService implements VaultService {
  @override
  Future<VaultItem> loadVaultHierarchy(String rootPath) async {
    // Giả lập độ trễ I/O 200ms
    await Future.delayed(const Duration(milliseconds: 200));

    return VaultItem(
      name: 'FPTU_SE_Notes',
      path: '/vault',
      isDirectory: true,
      children: [
        VaultItem(
          name: 'PRM393_Mobile_Programming',
          path: '/vault/PRM393_Mobile_Programming',
          isDirectory: true,
          children: [
            VaultItem(
              name: 'Flutter_Architecture.md',
              path: '/vault/PRM393_Mobile_Programming/Flutter_Architecture.md',
              isDirectory: false,
            ),
            VaultItem(
              name: 'Provider_Pattern.md',
              path: '/vault/PRM393_Mobile_Programming/Provider_Pattern.md',
              isDirectory: false,
            ),
          ],
        ),
        VaultItem(
          name: 'SWE201_Software_Process',
          path: '/vault/SWE201_Software_Process',
          isDirectory: true,
          children: [
            VaultItem(
              name: 'Agile_Scrum_Overview.md',
              path: '/vault/SWE201_Software_Process/Agile_Scrum_Overview.md',
              isDirectory: false,
            ),
          ],
        ),
        VaultItem(
          name: 'CSD201_Data_Structures',
          path: '/vault/CSD201_Data_Structures',
          isDirectory: true,
          children: [
            VaultItem(
              name: 'Graph_Algorithms.md',
              path: '/vault/CSD201_Data_Structures/Graph_Algorithms.md',
              isDirectory: false,
            ),
          ],
        ),
        VaultItem(
          name: 'Quick_Ideas.md',
          path: '/vault/Quick_Ideas.md',
          isDirectory: false,
        ),
        VaultItem(
          name: 'Daily_Thoughts.md',
          path: '/vault/Daily_Thoughts.md',
          isDirectory: false,
        ),
      ],
    );
  }

  @override
  Future<VaultItem> createFolder(String parentPath, String folderName) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return VaultItem(
      name: folderName,
      path: '$parentPath/$folderName',
      isDirectory: true,
      children: const [],
    );
  }

  @override
  Future<VaultItem> createNote(String parentPath, String noteName) async {
    final fileName = noteName.endsWith('.md') ? noteName : '$noteName.md';
    await Future.delayed(const Duration(milliseconds: 100));
    return VaultItem(
      name: fileName,
      path: '$parentPath/$fileName',
      isDirectory: false,
    );
  }

  @override
  Future<void> renameItem(String oldPath, String newName) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<void> deleteItem(String targetPath) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
