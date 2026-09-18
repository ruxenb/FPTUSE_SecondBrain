import 'package:flutter/foundation.dart';
import '../contracts/note_repository.dart';
import '../models/note.dart';
import 'note_provider.dart';

// ─── Data Classes cho Graph ───

/// Đại diện cho 1 node trên đồ thị (tương ứng 1 bài Note).
class GraphNode {
  final String id;    // Unique ID = note title (lowercase)
  final String title; // Tên hiển thị trên node
  final String path;  // Đường dẫn file để mở note khi click

  const GraphNode({
    required this.id,
    required this.title,
    required this.path,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is GraphNode && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Đại diện cho 1 cạnh liên kết giữa 2 node (tương ứng 1 [[WikiLink]]).
class GraphEdge {
  final String sourceId; // Node gốc (note chứa [[link]])
  final String targetId; // Node đích (note được trỏ tới)

  const GraphEdge({
    required this.sourceId,
    required this.targetId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GraphEdge && sourceId == other.sourceId && targetId == other.targetId;

  @override
  int get hashCode => Object.hash(sourceId, targetId);
}

// ─── Provider ───

/// [Member 4 - T4.4] Quản lý trạng thái và dữ liệu đồ thị liên kết tri thức.
///
/// Chuyển đổi danh sách Note + outgoingLinks thành tập hợp [GraphNode] và [GraphEdge]
/// tương thích với thư viện `graphview` để vẽ Knowledge Graph.
class GraphProvider extends ChangeNotifier {
  final NoteRepository noteRepository;

  GraphProvider({required this.noteRepository});

  // ─── State ───
  bool _isLoading = false;
  List<GraphNode> _nodes = [];
  List<GraphEdge> _edges = [];
  String? _activeNodeId; // Node đang được highlight (note đang mở)

  // ─── Getters ───
  bool get isLoading => _isLoading;
  List<GraphNode> get nodes => List.unmodifiable(_nodes);
  List<GraphEdge> get edges => List.unmodifiable(_edges);
  String? get activeNodeId => _activeNodeId;
  bool get hasGraph => _nodes.isNotEmpty;

  /// Được gọi tự động bởi `ChangeNotifierProxyProvider` khi `NoteProvider` thay đổi.
  /// Cập nhật node đang active và trigger rebuild graph nếu cần.
  void updateFromNoteProvider(NoteProvider noteProvider) {
    final currentNote = noteProvider.currentNote;
    final newActiveId = currentNote?.title.toLowerCase();

    if (newActiveId != _activeNodeId) {
      _activeNodeId = newActiveId;
      notifyListeners();
    }
  }

  /// Quét toàn bộ Vault, phân tích liên kết và xây dựng đồ thị Nodes + Edges.
  Future<void> loadGraph(String vaultRootPath) async {
    _isLoading = true;
    notifyListeners();

    try {
      final notes = await noteRepository.getAllNotes(vaultRootPath);
      _buildGraphFromNotes(notes);
      debugPrint('[GraphProvider] Built graph: ${_nodes.length} nodes, ${_edges.length} edges');
    } catch (e) {
      debugPrint('[GraphProvider] Error loading graph: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Thuật toán chuyển đổi danh sách Note → Nodes + Edges.
  void _buildGraphFromNotes(List<Note> notes) {
    final nodeMap = <String, GraphNode>{};
    final edgeSet = <GraphEdge>{};

    // Bước 1: Tạo node cho mỗi note thực tế
    for (final note in notes) {
      final id = note.title.toLowerCase();
      nodeMap[id] = GraphNode(
        id: id,
        title: note.title,
        path: note.path,
      );
    }

    // Bước 2: Duyệt outgoingLinks để tạo edges
    for (final note in notes) {
      final sourceId = note.title.toLowerCase();

      for (final linkTitle in note.outgoingLinks) {
        final targetId = linkTitle.toLowerCase();

        // Nếu note đích chưa có trong nodeMap (note chưa tồn tại),
        // vẫn tạo node "phantom" để hiển thị trên graph
        if (!nodeMap.containsKey(targetId)) {
          nodeMap[targetId] = GraphNode(
            id: targetId,
            title: linkTitle,
            path: '', // Phantom node, chưa có file thực
          );
        }

        // Tránh self-loop
        if (sourceId != targetId) {
          edgeSet.add(GraphEdge(sourceId: sourceId, targetId: targetId));
        }
      }
    }

    _nodes = nodeMap.values.toList();
    _edges = edgeSet.toList();
  }

  /// Đặt node active khi click trên graph (trước khi mở note).
  void setActiveNode(String nodeId) {
    _activeNodeId = nodeId;
    notifyListeners();
  }

  /// Xóa graph (khi đóng Vault).
  void clearGraph() {
    _nodes = [];
    _edges = [];
    _activeNodeId = null;
    notifyListeners();
  }
}
