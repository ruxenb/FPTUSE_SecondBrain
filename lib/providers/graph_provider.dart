import 'package:flutter/foundation.dart';
import '../contracts/note_repository.dart';
import 'note_provider.dart';

/// Quản lý trạng thái và dữ liệu đồ thị liên kết tri thức (Knowledge Graph).
/// [MEMBER 4] sẽ hoàn thiện logic tại đây theo Task T4.4.
class GraphProvider extends ChangeNotifier {
  final NoteRepository noteRepository;

  GraphProvider({required this.noteRepository});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void updateFromNoteProvider(NoteProvider noteProvider) {
    // TODO: [Member 4] Lắng nghe khi bài note thay đổi để refresh đồ thị
  }

  // TODO: [Member 4] Xây dựng đồ thị Graph (Nodes, Edges) từ danh sách notes
  Future<void> loadGraph(String vaultRootPath) async {
    _isLoading = true;
    notifyListeners();

    try {
      final notes = await noteRepository.getAllNotes(vaultRootPath);
      debugPrint('Loaded ${notes.length} notes for graph.');
    } catch (e) {
      debugPrint('Error loading graph: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
