import '../models/note.dart';

/// Interface xử lý nội dung chi tiết của Note và phân tích liên kết hai chiều.
/// Phụ trách: Member 2
abstract class NoteRepository {
  /// Đọc nội dung bài note từ đường dẫn và trích xuất các outgoing links
  Future<Note> getNote(String filePath);

  /// Lưu nội dung note xuống ổ đĩa
  Future<void> saveNote(Note note);

  /// Lấy danh sách tất cả các bài note trong Vault để phục vụ Graph & Backlinks
  Future<List<Note>> getAllNotes(String vaultRootPath);

  /// Trích xuất danh sách tên các liên kết dạng [[Tên Note]] từ văn bản
  List<String> extractWikilinks(String markdownContent);

  /// Tìm kiếm danh sách các note có chứa liên kết trỏ về note mục tiêu
  Future<List<String>> getBacklinksForNote(String noteTitle, String vaultRootPath);
}
