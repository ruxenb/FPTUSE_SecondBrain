import 'dart:async';

import 'package:flutter/foundation.dart';

import '../contracts/note_repository.dart';
import '../models/note.dart';

/// Quản lý trạng thái bài Note đang mở, soạn thảo và backlinks.
class NoteProvider extends ChangeNotifier {
  static const _autoSaveDelay = Duration(seconds: 1);

  final NoteRepository noteRepository;

  NoteProvider({required this.noteRepository});

  Note? _currentNote;
  String? _vaultRootPath;
  Timer? _autoSaveTimer;
  Future<bool>? _activeSave;
  bool _isLoading = false;
  bool _isDirty = false;
  bool _isSaving = false;
  String? _errorMessage;
  int _openRequestId = 0;
  int _saveRequestId = 0;

  Note? get currentNote => _currentNote;
  bool get isLoading => _isLoading;
  bool get isDirty => _isDirty;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get vaultRootPath => _vaultRootPath;
  bool get hasNote => _currentNote != null;
  bool get hasError => _errorMessage != null;

  /// Member 1 gọi hàm này khi Vault hiện tại thay đổi.
  /// Sidebar vẫn chỉ cần gọi [openNote] với filePath.
  void setVaultRootPath(String? vaultRootPath) {
    _vaultRootPath = vaultRootPath;
  }

  Future<void> openNote(String filePath, {String? vaultRoot}) async {
    while (_currentNote != null && _currentNote!.path != filePath && _isDirty) {
      _autoSaveTimer?.cancel();
      final saved = await _saveCurrentNote();
      if (!saved) {
        return;
      }
    }

    _autoSaveTimer?.cancel();
    final requestId = ++_openRequestId;
    ++_saveRequestId;

    if (vaultRoot != null) {
      _vaultRootPath = vaultRoot;
    }

    _currentNote = null;
    _isLoading = true;
    _isDirty = false;
    _isSaving = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final note = await noteRepository.getNote(filePath);
      if (requestId != _openRequestId) {
        return;
      }

      _currentNote = note;
      await refreshBacklinks(notify: false);
    } catch (error, stackTrace) {
      if (requestId == _openRequestId) {
        _currentNote = null;
        _errorMessage = 'Could not open note: $error';
        debugPrintStack(stackTrace: stackTrace, label: 'Error opening note');
      }
    } finally {
      if (requestId == _openRequestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void updateContent(String content) {
    final note = _currentNote;
    if (note == null || note.content == content) {
      return;
    }

    _currentNote = note.copyWith(
      content: content,
      outgoingLinks: noteRepository.extractWikilinks(content),
      lastModified: DateTime.now(),
    );
    _isDirty = true;
    _errorMessage = null;
    _scheduleAutoSave();
    notifyListeners();
  }

  Future<void> saveCurrentNote() async {
    await _saveCurrentNote();
  }

  Future<bool> _saveCurrentNote() {
    _autoSaveTimer?.cancel();
    final activeSave = _activeSave;
    if (activeSave != null) {
      return activeSave;
    }

    final noteToSave = _currentNote;
    if (noteToSave == null) {
      return Future.value(true);
    }

    final saveOperation = _performSave(noteToSave);
    _activeSave = saveOperation;
    return saveOperation;
  }

  Future<bool> _performSave(Note noteToSave) async {
    final requestId = ++_saveRequestId;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await noteRepository.saveNote(noteToSave);
      if (requestId != _saveRequestId) {
        return true;
      }

      final currentNote = _currentNote;
      if (currentNote != null &&
          currentNote.path == noteToSave.path &&
          currentNote.content == noteToSave.content) {
        _isDirty = false;
      }
      await refreshBacklinks(notify: false);
      return true;
    } catch (error, stackTrace) {
      if (requestId == _saveRequestId) {
        _errorMessage = 'Could not save note: $error';
        debugPrintStack(stackTrace: stackTrace, label: 'Error saving note');
      }
      return false;
    } finally {
      _activeSave = null;
      if (requestId == _saveRequestId) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }

  Future<void> refreshBacklinks({bool notify = true}) async {
    final note = _currentNote;
    final vaultRootPath = _vaultRootPath;
    if (note == null || vaultRootPath == null) {
      return;
    }

    try {
      final backlinks = await noteRepository.getBacklinksForNote(
        note.title,
        vaultRootPath,
      );
      final currentNote = _currentNote;
      if (currentNote != null && currentNote.path == note.path) {
        _currentNote = currentNote.copyWith(backlinks: backlinks);
        if (notify) {
          notifyListeners();
        }
      }
    } catch (error, stackTrace) {
      _errorMessage = 'Could not refresh backlinks: $error';
      debugPrintStack(
        stackTrace: stackTrace,
        label: 'Error refreshing backlinks',
      );
      if (notify) {
        notifyListeners();
      }
    }
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(_autoSaveDelay, () {
      unawaited(saveCurrentNote());
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}
