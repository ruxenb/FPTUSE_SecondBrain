/// Đại diện cho một phần tử trong cây thư mục Vault (Tệp tin hoặc Thư mục).
/// Phụ trách: Member 1 (Vault & Filesystem)
class VaultItem {
  final String name;
  final String path;
  final bool isDirectory;
  final List<VaultItem> children;

  VaultItem({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.children = const [],
  });

  bool get isMarkdown => !isDirectory && name.toLowerCase().endsWith('.md');

  VaultItem copyWith({
    String? name,
    String? path,
    bool? isDirectory,
    List<VaultItem>? children,
  }) {
    return VaultItem(
      name: name ?? this.name,
      path: path ?? this.path,
      isDirectory: isDirectory ?? this.isDirectory,
      children: children ?? this.children,
    );
  }
}
