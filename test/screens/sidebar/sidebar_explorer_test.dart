import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fptu_se_second_brain/contracts/note_repository.dart';
import 'package:fptu_se_second_brain/contracts/vault_service.dart';
import 'package:fptu_se_second_brain/models/note.dart';
import 'package:fptu_se_second_brain/models/vault_item.dart';
import 'package:fptu_se_second_brain/providers/note_provider.dart';
import 'package:fptu_se_second_brain/providers/vault_provider.dart';
import 'package:fptu_se_second_brain/screens/sidebar/sidebar_explorer.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

void main() {
  Future<void> pumpSidebar(
    WidgetTester tester, {
    required VaultProvider vaultProvider,
    required NoteProvider noteProvider,
    required VaultService vaultService,
    required NoteRepository noteRepository,
  }) async {
    tester.view.physicalSize = const Size(600, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    addTearDown(vaultProvider.dispose);
    addTearDown(noteProvider.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<VaultService>.value(value: vaultService),
          Provider<NoteRepository>.value(value: noteRepository),
          ChangeNotifierProvider<VaultProvider>.value(value: vaultProvider),
          ChangeNotifierProvider<NoteProvider>.value(value: noteProvider),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SizedBox(width: 280, child: SidebarExplorer())),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> confirmDelete(WidgetTester tester, String fileName) async {
    await tester.tap(find.text(fileName), buttons: kSecondaryMouseButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa').last);
    await tester.pumpAndSettle();
    expect(find.text('Xóa note?'), findsOneWidget);
    await tester.tap(find.text('Xóa').last);
    await tester.pump();
  }

  testWidgets('creating a note from the Sidebar opens the returned path', (
    tester,
  ) async {
    final vaultService = _SidebarVaultService();
    final noteRepository = _SidebarNoteRepository();
    final vaultProvider = VaultProvider(vaultService: vaultService);
    final noteProvider = NoteProvider(noteRepository: noteRepository);
    await vaultProvider.openVault('/vault');
    noteProvider.setVaultRootPath('/vault');
    await pumpSidebar(
      tester,
      vaultProvider: vaultProvider,
      noteProvider: noteProvider,
      vaultService: vaultService,
      noteRepository: noteRepository,
    );

    await tester.tap(find.byTooltip('Tạo note ở Vault'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'New Note');
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();

    expect(noteProvider.currentNote?.path, '/vault/New Note.md');
    expect(noteProvider.currentNote?.title, 'New Note');
  });

  testWidgets(
    'deleting a dirty open note waits for save and never resurrects it',
    (tester) async {
      final item = VaultItem(
        name: 'Flutter.md',
        path: '/vault/Flutter.md',
        isDirectory: false,
      );
      final vaultService = _SidebarVaultService(initialItem: item);
      final saveGate = Completer<void>();
      final noteRepository = _SidebarNoteRepository(saveGate: saveGate);
      final vaultProvider = VaultProvider(vaultService: vaultService);
      final noteProvider = NoteProvider(noteRepository: noteRepository);
      await vaultProvider.openVault('/vault');
      noteProvider.setVaultRootPath('/vault');
      await noteProvider.openNote(item.path);
      noteProvider.updateContent('# Flutter\n\nUnsaved change.\n');
      await pumpSidebar(
        tester,
        vaultProvider: vaultProvider,
        noteProvider: noteProvider,
        vaultService: vaultService,
        noteRepository: noteRepository,
      );

      await confirmDelete(tester, 'Flutter.md');
      await tester.pump();
      expect(noteProvider.isSaving, isTrue);
      expect(vaultService.deletedPaths, isEmpty);

      saveGate.complete();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 1200));

      expect(noteProvider.currentNote, isNull);
      expect(vaultService.deletedPaths, [item.path]);
      expect(noteRepository.savedNotes, hasLength(1));
    },
  );

  testWidgets('delete aborts when a dirty open note cannot be saved', (
    tester,
  ) async {
    final item = VaultItem(
      name: 'Flutter.md',
      path: '/vault/Flutter.md',
      isDirectory: false,
    );
    final vaultService = _SidebarVaultService(initialItem: item);
    final noteRepository = _SidebarNoteRepository(failSave: true);
    final vaultProvider = VaultProvider(vaultService: vaultService);
    final noteProvider = NoteProvider(noteRepository: noteRepository);
    await vaultProvider.openVault('/vault');
    noteProvider.setVaultRootPath('/vault');
    await noteProvider.openNote(item.path);
    noteProvider.updateContent('# Flutter\n\nMust remain.\n');
    await pumpSidebar(
      tester,
      vaultProvider: vaultProvider,
      noteProvider: noteProvider,
      vaultService: vaultService,
      noteRepository: noteRepository,
    );

    await confirmDelete(tester, 'Flutter.md');
    await tester.pumpAndSettle();

    expect(vaultService.deletedPaths, isEmpty);
    expect(noteProvider.currentNote?.content, contains('Must remain'));
    expect(noteProvider.isDirty, isTrue);
    expect(noteProvider.errorMessage, contains('Could not save note'));
  });
}

class _SidebarVaultService implements VaultService {
  final VaultItem? initialItem;
  VaultItem? createdItem;
  final deletedPaths = <String>[];

  _SidebarVaultService({this.initialItem});

  @override
  Future<VaultItem> loadVaultHierarchy(String rootPath) async {
    final visibleInitialItem =
        initialItem != null && !deletedPaths.contains(initialItem!.path)
        ? initialItem
        : null;
    return VaultItem(
      name: 'vault',
      path: '/vault',
      isDirectory: true,
      children: [?visibleInitialItem, ?createdItem],
    );
  }

  @override
  Future<VaultItem> createNote(String parentPath, String noteName) async {
    createdItem = VaultItem(
      name: '$noteName.md',
      path: '$parentPath/$noteName.md',
      isDirectory: false,
    );
    return createdItem!;
  }

  @override
  Future<VaultItem> createFolder(String parentPath, String folderName) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteItem(String targetPath) async {
    deletedPaths.add(targetPath);
  }

  @override
  Future<void> renameItem(String oldPath, String newName) async {}
}

class _SidebarNoteRepository implements NoteRepository {
  final Completer<void>? saveGate;
  final bool failSave;
  final savedNotes = <Note>[];

  _SidebarNoteRepository({this.saveGate, this.failSave = false});

  @override
  List<String> extractWikilinks(String markdownContent) => const [];

  @override
  Future<List<Note>> getAllNotes(String vaultRootPath) async => const [];

  @override
  Future<List<String>> getBacklinksForNote(
    String noteTitle,
    String vaultRootPath,
  ) async => const [];

  @override
  Future<Note> getNote(String filePath) async => Note(
    path: filePath,
    title: path.basenameWithoutExtension(filePath),
    content: '# ${path.basenameWithoutExtension(filePath)}\n',
    outgoingLinks: const [],
  );

  @override
  Future<void> saveNote(Note note) async {
    await saveGate?.future;
    if (failSave) {
      throw StateError('Simulated save failure');
    }
    savedNotes.add(note);
  }
}
