import 'package:path/path.dart' as path;

import '../core/utils/wikilink_parser.dart';
import '../contracts/note_repository.dart';
import '../models/note.dart';

/// Triển khai giả lập lưu trữ ghi chú và phân tích liên kết In-Memory.
/// Sẵn sàng cho Day 2 để Member 2, 3, 4 test Editor, AI và Knowledge Graph.
class MockNoteRepository implements NoteRepository {
  final Map<String, Note> _memoryNotes = {
    '/vault/PRM393_Mobile_Programming/Flutter_Architecture.md': Note(
      path: '/vault/PRM393_Mobile_Programming/Flutter_Architecture.md',
      title: 'Flutter_Architecture',
      content: '''# Kiến Trúc Ứng Dụng Flutter Desktop

Trong môn PRM393, việc phân tách các tầng kiến trúc là bắt buộc:
1. **Presentation Layer**: Widget UI và Screens.
2. **State Management**: Sử dụng [[Provider_Pattern]] để quản lý trạng thái.
3. **Data Layer**: Tách biệt rõ giữa Service (I/O) và Repository.

Tham khảo thêm quy trình phát triển Agile tại [[Agile_Scrum_Overview]].
Mô hình đồ thị tri thức dựa trên [[Graph_Algorithms]].
''',
      outgoingLinks: [
        'Provider_Pattern',
        'Agile_Scrum_Overview',
        'Graph_Algorithms',
      ],
      backlinks: ['Quick_Ideas', 'Provider_Pattern'],
    ),
    '/vault/PRM393_Mobile_Programming/Provider_Pattern.md': Note(
      path: '/vault/PRM393_Mobile_Programming/Provider_Pattern.md',
      title: 'Provider_Pattern',
      content: '''# Quản Lý Trạng Thái Với Provider

Provider là thư viện bọc quanh `InheritedWidget`:
- Sử dụng `ChangeNotifierProvider` cho các luồng dữ liệu cần lắng nghe thay đổi.
- Widget gọi `context.watch<T>()` hoặc `context.read<T>()`.
- Tách biệt UI khỏi logic nghiệp vụ theo chuẩn [[Flutter_Architecture]].
''',
      outgoingLinks: ['Flutter_Architecture'],
      backlinks: ['Flutter_Architecture'],
    ),
    '/vault/SWE201_Software_Process/Agile_Scrum_Overview.md': Note(
      path: '/vault/SWE201_Software_Process/Agile_Scrum_Overview.md',
      title: 'Agile_Scrum_Overview',
      content: '''# Tổng Quan Về Agile & Scrum

Mô hình phát triển phần mềm lặp (Iterative):
- Sprint Planning & Daily Standup.
- Mỗi Sprint chuyển giao một MVP hoàn chỉnh.
- Liên kết với kiến trúc thực tế tại [[Flutter_Architecture]].
''',
      outgoingLinks: ['Flutter_Architecture'],
      backlinks: ['Flutter_Architecture'],
    ),
    '/vault/CSD201_Data_Structures/Graph_Algorithms.md': Note(
      path: '/vault/CSD201_Data_Structures/Graph_Algorithms.md',
      title: 'Graph_Algorithms',
      content: '''# Cấu Trúc Dữ Liệu & Giải Thuật Đồ Thị

- Directed Graph (Đồ thị có hướng) và Nodes / Edges.
- Ứng dụng vẽ mạng lưới tri thức Second Brain cho [[Flutter_Architecture]].
''',
      outgoingLinks: ['Flutter_Architecture'],
      backlinks: ['Flutter_Architecture'],
    ),
    '/vault/Quick_Ideas.md': Note(
      path: '/vault/Quick_Ideas.md',
      title: 'Quick_Ideas',
      content: '''# Ý Tưởng Nhanh

Ghi chú ngắn: Cần tối ưu hiệu năng render markdown khi xem [[Flutter_Architecture]].
''',
      outgoingLinks: ['Flutter_Architecture'],
      backlinks: [],
    ),
  };

  @override
  Future<Note> getNote(String filePath) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (_memoryNotes.containsKey(filePath)) {
      return _memoryNotes[filePath]!;
    }
    final title = path.basenameWithoutExtension(filePath);
    return Note(
      path: filePath,
      title: title,
      content: '# $title\n\nBắt đầu ghi chú bài học mới tại đây...',
      outgoingLinks: const [],
      backlinks: const [],
    );
  }

  @override
  Future<void> saveNote(Note note) async {
    await Future.delayed(const Duration(milliseconds: 80));
    final links = extractWikilinks(note.content);
    _memoryNotes[note.path] = note.copyWith(outgoingLinks: links);
  }

  @override
  Future<List<Note>> getAllNotes(String vaultRootPath) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _memoryNotes.values.toList();
  }

  @override
  List<String> extractWikilinks(String markdownContent) {
    return WikilinkParser.extract(markdownContent);
  }

  @override
  Future<List<String>> getBacklinksForNote(
    String noteTitle,
    String vaultRootPath,
  ) async {
    await Future.delayed(const Duration(milliseconds: 80));
    final backlinks = <String>[];
    for (final entry in _memoryNotes.entries) {
      if (!WikilinkParser.titlesEqual(entry.value.title, noteTitle)) {
        final links = extractWikilinks(entry.value.content);
        if (links.any((link) => WikilinkParser.titlesEqual(link, noteTitle))) {
          backlinks.add(entry.value.title);
        }
      }
    }
    return backlinks;
  }
}
