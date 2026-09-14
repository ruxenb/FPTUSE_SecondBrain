import 'package:flutter/foundation.dart';
import 'package:graphview/GraphView.dart';
import '../contracts/note_repository.dart';
import '../models/note.dart';
import 'note_provider.dart';

/// Quản lý dữ liệu đồ thị mạng lưới tri thức (Knowledge Graph).
/// Phụ trách: Member 4
class GraphProvider extends ChangeNotifier {
  final NoteRepository noteRepository;

  GraphProvider({required this.noteRepository});

  final Graph graph = Graph()..isTree = false;
  final Map<String, Node> _nodeMap = {};
  List<Note> _allNotes = [];
  bool _isLoading = false;

  List<Note> get allNotes => List.unmodifiable(_allNotes);
  bool get isLoading => _isLoading;
  bool get hasNodes => _nodeMap.isNotEmpty;

  /// Cập nhật từ NoteProvider khi người dùng lưu note mới
  void updateFromNoteProvider(NoteProvider noteProvider) {
    // Có thể lắng nghe sự kiện lưu để refresh đồ thị
  }

  /// Tải dữ liệu toàn bộ notes trong Vault và dựng đồ thị
  Future<void> loadGraph(String vaultRootPath) async {
    _isLoading = true;
    notifyListeners();

    try {
      _allNotes = await noteRepository.getAllNotes(vaultRootPath);
      _buildGraphFromNotes(_allNotes);
    } catch (e) {
      debugPrint('Lỗi dựng Knowledge Graph: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _buildGraphFromNotes(List<Note> notes) {
    // Làm sạch đồ thị cũ
    _nodeMap.clear();

    // 1. Tạo Node cho từng bài Note
    for (final note in notes) {
      final node = Node.Id(note.title);
      _nodeMap[note.title.toLowerCase()] = node;
      graph.addNode(node);
    }

    // 2. Tạo Edge (cạnh nối) cho các outgoingLinks
    for (final note in notes) {
      final sourceNode = _nodeMap[note.title.toLowerCase()];
      if (sourceNode == null) continue;

      for (final linkTitle in note.outgoingLinks) {
        var targetNode = _nodeMap[linkTitle.toLowerCase()];
        if (targetNode == null) {
          // Tạo node tạm cho bài note chưa được tạo file
          targetNode = Node.Id(linkTitle);
          _nodeMap[linkTitle.toLowerCase()] = targetNode;
          graph.addNode(targetNode);
        }
        graph.addEdge(sourceNode, targetNode);
      }
    }
  }
}
