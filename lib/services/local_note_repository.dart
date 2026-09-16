import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../contracts/note_repository.dart';
import '../core/utils/wikilink_parser.dart';
import '../models/note.dart';

/// NoteRepository lưu Markdown UTF-8 trực tiếp trong Vault trên ổ đĩa.
class LocalNoteRepository implements NoteRepository {
  @override
  Future<Note> getNote(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('Markdown file does not exist.', filePath);
    }

    final content = await file.readAsString(encoding: utf8);
    final stat = await file.stat();
    return Note(
      path: file.path,
      title: path.basenameWithoutExtension(file.path),
      content: content,
      outgoingLinks: extractWikilinks(content),
      lastModified: stat.modified,
    );
  }

  @override
  Future<void> saveNote(Note note) async {
    final file = File(note.path);
    final parent = file.parent;
    if (!await parent.exists()) {
      throw FileSystemException('Parent folder does not exist.', parent.path);
    }

    final temporaryFile = File(
      path.join(parent.path, '.${path.basename(file.path)}.writing'),
    );
    try {
      await temporaryFile.writeAsString(
        note.content,
        encoding: utf8,
        flush: true,
      );
      await temporaryFile.rename(file.path);
    } finally {
      if (await temporaryFile.exists()) {
        await temporaryFile.delete();
      }
    }
  }

  @override
  Future<List<Note>> getAllNotes(String vaultRootPath) async {
    final root = Directory(vaultRootPath);
    if (!await root.exists()) {
      throw FileSystemException('Vault folder does not exist.', vaultRootPath);
    }

    final files = <File>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is File &&
          path.extension(entity.path).toLowerCase() == '.md') {
        files.add(entity);
      }
    }
    files.sort(
      (first, second) =>
          first.path.toLowerCase().compareTo(second.path.toLowerCase()),
    );

    return Future.wait(files.map((file) => getNote(file.path)));
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
    final notes = await getAllNotes(vaultRootPath);
    return [
      for (final note in notes)
        if (!WikilinkParser.titlesEqual(note.title, noteTitle) &&
            note.outgoingLinks.any(
              (link) => WikilinkParser.titlesEqual(link, noteTitle),
            ))
          note.title,
    ];
  }
}
