import 'dart:io';
import 'package:path/path.dart' as p;
import '../contracts/note_repository.dart';
import '../models/note.dart';

/// Triển khai thực tế đọc ghi file Markdown trên ổ đĩa và phân tích liên kết.
/// Phụ trách triển khai vào Tuần 2: Member 2
class LocalNoteRepository implements NoteRepository {
  @override
  Future<Note> getNote(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      final title = p.basenameWithoutExtension(filePath);
      return Note(
        path: filePath,
        title: title,
        content: '# $title\n\n',
        outgoingLinks: const [],
        backlinks: const [],
      );
    }

    final content = await file.readAsString();
    final stat = await file.stat();
    final outgoing = extractWikilinks(content);
    final title = p.basenameWithoutExtension(filePath);

    return Note(
      path: filePath,
      title: title,
      content: content,
      outgoingLinks: outgoing,
      lastModified: stat.modified,
    );
  }

  @override
  Future<void> saveNote(Note note) async {
    final file = File(note.path);
    // Ghi an toàn
    await file.writeAsString(note.content, flush: true);
  }

  @override
  Future<List<Note>> getAllNotes(String vaultRootPath) async {
    final rootDir = Directory(vaultRootPath);
    if (!await rootDir.exists()) return [];

    final notes = <Note>[];
    await for (final entity in rootDir.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.toLowerCase().endsWith('.md')) {
        final note = await getNote(entity.path);
        notes.add(note);
      }
    }
    return notes;
  }

  @override
  List<String> extractWikilinks(String markdownContent) {
    final regex = RegExp(r'\[\[(.*?)\]\]');
    final matches = regex.allMatches(markdownContent);
    return matches
        .map((m) => m.group(1)?.trim() ?? '')
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
  }

  @override
  Future<List<String>> getBacklinksForNote(String noteTitle, String vaultRootPath) async {
    final allNotes = await getAllNotes(vaultRootPath);
    final backlinks = <String>[];
    for (final note in allNotes) {
      if (note.title.toLowerCase() != noteTitle.toLowerCase()) {
        final links = extractWikilinks(note.content);
        if (links.any((l) => l.toLowerCase() == noteTitle.toLowerCase())) {
          backlinks.add(note.title);
        }
      }
    }
    return backlinks;
  }
}
