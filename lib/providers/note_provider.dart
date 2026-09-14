import 'package:flutter/foundation.dart';
import '../contracts/note_repository.dart';
import '../models/note.dart';

/// Quản lý trạng thái bài Note đang mở, soạn thảo và backlinks.
/// [MEMBER 2] sẽ hoàn thiện logic tại đây theo Task T2.3.
class NoteProvider extends ChangeNotifier {
  final NoteRepository noteRepository;

  NoteProvider({required this.noteRepository});

  Note? _currentNote;
  bool _isLoading = false;

  Note? get currentNote => _currentNote;
  bool get isLoading => _isLoading;
  bool get hasNote => _currentNote != null;

  // TODO: [Member 2] Hiện thực hàm mở note từ filePath
  Future<void> openNote(String filePath, {String? vaultRoot}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentNote = await noteRepository.getNote(filePath);
    } catch (e) {
      debugPrint('Error opening note: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // TODO: [Member 2] Hiện thực hàm updateContent, auto-save (Debounce), saveCurrentNote...
}
