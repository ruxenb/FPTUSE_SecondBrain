import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fptu_se_second_brain/providers/note_provider.dart';
import 'package:fptu_se_second_brain/providers/vault_provider.dart';
import 'package:fptu_se_second_brain/services/local_note_repository.dart';
import 'package:fptu_se_second_brain/services/local_vault_service.dart';
import 'package:path/path.dart' as path;

void main() {
  late Directory vaultDirectory;
  late VaultProvider vaultProvider;
  late NoteProvider noteProvider;

  setUp(() async {
    vaultDirectory = await Directory.systemTemp.createTemp(
      'note_lifecycle_integration_',
    );
    vaultProvider = VaultProvider(vaultService: LocalVaultService());
    noteProvider = NoteProvider(noteRepository: LocalNoteRepository());
    await vaultProvider.openVault(vaultDirectory.path);
    noteProvider.setVaultRootPath(vaultDirectory.path);
  });

  tearDown(() async {
    vaultProvider.dispose();
    noteProvider.dispose();
    if (await vaultDirectory.exists()) {
      await vaultDirectory.delete(recursive: true);
    }
  });

  test(
    'real create, missing-link open and dirty delete do not resurrect',
    () async {
      final source = await vaultProvider.createNote(
        vaultDirectory.path,
        'Source',
      );
      expect(source, isNotNull);
      expect(path.isAbsolute(source!.path), isTrue);
      expect(await File(source.path).exists(), isTrue);
      expect(
        vaultProvider.rootItem?.children.map((item) => item.path),
        contains(source.path),
      );

      await noteProvider.openNote(source.path);
      noteProvider.updateContent('# Source\n\nOpen [[MissingNote]].\n');
      await noteProvider.saveCurrentNote();

      final created = await vaultProvider.createNote(
        path.dirname(noteProvider.currentNote!.path),
        'MissingNote',
      );
      expect(created, isNotNull);
      expect(await File(created!.path).exists(), isTrue);
      await noteProvider.openNote(created.path);
      expect(noteProvider.currentNote?.path, created.path);
      expect(noteProvider.currentNote?.title, 'MissingNote');

      noteProvider.updateContent('# MissingNote\n\nNội dung UTF-8 chưa lưu.\n');
      expect(noteProvider.isDirty, isTrue);
      expect(await noteProvider.closeCurrentNoteSafely(), isTrue);
      expect(noteProvider.currentNote, isNull);
      expect(
        await File(created.path).readAsString(),
        '# MissingNote\n\nNội dung UTF-8 chưa lưu.\n',
      );

      expect(await vaultProvider.deleteItem(created.path), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      expect(await File(created.path).exists(), isFalse);
    },
  );
}
