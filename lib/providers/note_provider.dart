import 'dart:async';
import 'package:flutter/foundation.dart';
import '../contracts/note_repository.dart';
import '../models/note.dart';

/// Quản lý trạng thái bài Note đang mở, chỉnh sửa, tự động lưu và backlinks.
/// Phụ trách: Member 2
class NoteProvider extends ChangeNotifier {
  final NoteRepository noteRepository;

  NoteProvider({required this.noteRepository});

  Note? _currentNote;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDirty = false;
  Timer? _debounceTimer;

  Note? get currentNote => _currentNote;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isDirty => _isDirty;
  bool get hasNote => _currentNote != null;

  /// Mở một bài note từ đường dẫn
  Future<void> openNote(String filePath, {String? vaultRoot}) async {
    _debounceTimer?.cancel();
    _isLoading = true;
    notifyListeners();

    try {
      final note = await noteRepository.getNote(filePath);
      List<String> backlinks = [];
      if (vaultRoot != null) {
        backlinks = await noteRepository.getBacklinksForNote(note.title, vaultRoot);
      }
      _currentNote = note.copyWith(backlinks: backlinks);
      _isDirty = false;
    } catch (e) {
      debugPrint('Lỗi mở note: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cập nhật nội dung khi người dùng gõ phím
  void updateContent(String newContent) {
    if (_currentNote == null) return;
    _currentNote = _currentNote!.copyWith(
      content: newContent,
      lastModified: DateTime.now(),
    );
    _isDirty = true;
    notifyListeners();

    // Tự động lưu sau 1.2s người dùng dừng gõ (Debounce)
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1200), () {
      saveCurrentNote();
    });
  }

  /// Lưu bài note hiện tại xuống ổ đĩa
  Future<void> saveCurrentNote() async {
    if (_currentNote == null || !_isDirty) return;
    _isSaving = true;
    notifyListeners();

    try {
      await noteRepository.saveNote(_currentNote!);
      _isDirty = false;
    } catch (e) {
      debugPrint('Lỗi lưu note: $e');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Đóng note hiện tại
  void closeNote() {
    _debounceTimer?.cancel();
    _currentNote = null;
    _isDirty = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
