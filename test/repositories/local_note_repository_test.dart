import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fptu_se_second_brain/models/note.dart';
import 'package:fptu_se_second_brain/services/local_note_repository.dart';

void main() {
  late Directory vault;
  late LocalNoteRepository repository;

  setUp(() async {
    vault = await Directory.systemTemp.createTemp('fptu_second_brain_test_');
    repository = LocalNoteRepository();
  });

  tearDown(() async {
    if (await vault.exists()) {
      await vault.delete(recursive: true);
    }
  });

  test('saves and reads UTF-8 Markdown', () async {
    final notePath = '${vault.path}${Platform.pathSeparator}Flutter.md';
    final original = Note(
      path: notePath,
      title: 'Flutter',
      content: '# Lập trình di động\n\nLearn [[Provider]].',
    );

    await repository.saveNote(original);
    await repository.saveNote(
      original.copyWith(content: '# Lập trình di động\n\nUpdated [[SQLite]].'),
    );
    final loaded = await repository.getNote(notePath);

    expect(loaded.content, '# Lập trình di động\n\nUpdated [[SQLite]].');
    expect(loaded.title, 'Flutter');
    expect(loaded.outgoingLinks, ['SQLite']);
  });

  test('finds backlinks case-insensitively and excludes self-links', () async {
    await File('${vault.path}${Platform.pathSeparator}Flutter.md')
        .writeAsString('See [[provider]].');
    await File('${vault.path}${Platform.pathSeparator}Provider.md')
        .writeAsString('Self reference [[Provider]].');

    final backlinks = await repository.getBacklinksForNote(
      'PROVIDER',
      vault.path,
    );

    expect(backlinks, ['Flutter']);
  });
}
