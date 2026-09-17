import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fptu_se_second_brain/services/local_vault_service.dart';
import 'package:path/path.dart' as path;

void main() {
  late Directory vault;
  late LocalVaultService service;

  setUp(() async {
    vault = await Directory.systemTemp.createTemp('fptu_vault_test_');
    service = LocalVaultService();
  });

  tearDown(() async {
    if (await vault.exists()) await vault.delete(recursive: true);
  });

  test(
    'scans Markdown, ignores hidden folders and orders folders first',
    () async {
      await File(path.join(vault.path, 'zeta.md')).writeAsString('z');
      await File(path.join(vault.path, 'ignored.txt')).writeAsString('x');
      await Directory(path.join(vault.path, 'Course')).create();
      await File(path.join(vault.path, 'Course', 'lesson.md'))
          .writeAsString('x');
      await Directory(path.join(vault.path, '.git')).create();
      await File(path.join(vault.path, '.git', 'hidden.md')).writeAsString('x');

      final root = await service.loadVaultHierarchy(vault.path);

      expect(root.children.map((item) => item.name), ['Course', 'zeta.md']);
      expect(root.children.first.children.single.name, 'lesson.md');
    },
  );

  test('creates, renames and deletes a Markdown note', () async {
    final note = await service.createNote(vault.path, 'Flutter');
    expect(note.name, 'Flutter.md');
    expect(await File(note.path).readAsString(), '# Flutter\n');

    await service.renameItem(note.path, 'Provider');
    final renamedPath = path.join(vault.path, 'Provider.md');
    expect(await File(renamedPath).exists(), isTrue);

    await service.deleteItem(renamedPath);
    expect(await File(renamedPath).exists(), isFalse);
  });

  test('rejects Windows-invalid names', () async {
    await expectLater(
      service.createFolder(vault.path, 'bad:name'),
      throwsArgumentError,
    );
  });
}
