import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fptu_se_second_brain/contracts/note_repository.dart';
import 'package:fptu_se_second_brain/core/utils/wikilink_parser.dart';
import 'package:fptu_se_second_brain/mocks/mock_note_repository.dart';
import 'package:fptu_se_second_brain/models/note.dart';
import 'package:fptu_se_second_brain/providers/note_provider.dart';
import 'package:fptu_se_second_brain/screens/editor/note_editor_screen.dart';
import 'package:provider/provider.dart';

void main() {
  const flutterArchitecturePath =
      '/vault/PRM393_Mobile_Programming/Flutter_Architecture.md';

  Future<NoteProvider> pumpEditor(
    WidgetTester tester, {
    NoteRepository? noteRepository,
    String initialPath = flutterArchitecturePath,
    MissingNoteCreator? onCreateMissingNote,
  }) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = noteRepository ?? MockNoteRepository();
    final provider = NoteProvider(noteRepository: repository);
    addTearDown(provider.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<NoteRepository>.value(value: repository),
          ChangeNotifierProvider<NoteProvider>.value(value: provider),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: NoteEditorScreen(onCreateMissingNote: onCreateMissingNote),
          ),
        ),
      ),
    );
    final openNote = provider.openNote(initialPath, vaultRoot: '/vault');
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 120));
    await openNote;
    await tester.pump();
    return provider;
  }

  testWidgets('loads a note into the desktop editor', (tester) async {
    await pumpEditor(tester);

    expect(find.byKey(const Key('markdown-editor')), findsOneWidget);
    expect(find.text('Flutter_Architecture'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets('switches between Edit and Preview and renders Markdown', (
    tester,
  ) async {
    await pumpEditor(tester);

    await tester.tap(find.text('Preview'));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byKey(const Key('markdown-editor')), findsNothing);
    expect(find.text('Kiến Trúc Ứng Dụng Flutter Desktop'), findsOneWidget);
  });

  testWidgets('opens an existing Wiki-link and shows backlinks', (
    tester,
  ) async {
    await pumpEditor(tester);

    expect(find.text('Backlinks'), findsOneWidget);
    expect(find.text('Quick_Ideas'), findsOneWidget);

    await tester.tap(find.text('Preview'));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Provider_Pattern').first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(find.text('Provider_Pattern'), findsWidgets);
  });

  testWidgets('Ctrl+S triggers manual save', (tester) async {
    final provider = await pumpEditor(tester);
    final editor = find.byKey(const Key('markdown-editor'));

    await tester.tap(editor);
    await tester.enterText(editor, 'Save this content manually.');
    await tester.pump();
    expect(provider.isDirty, isTrue);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(provider.isDirty, isFalse);
    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets('creates a missing Wiki-link target and opens returned path', (
    tester,
  ) async {
    final repository = _MissingLinkRepository();
    final requestedTitles = <String>[];
    final provider = await pumpEditor(
      tester,
      noteRepository: repository,
      initialPath: _MissingLinkRepository.sourcePath,
      onCreateMissingNote: (title) async {
        requestedTitles.add(title);
        return _MissingLinkRepository.createdPath;
      },
    );

    await tester.tap(find.text('Preview'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('markdown-editor')), findsNothing);
    await tester.tap(find.text('MissingNote', findRichText: true));
    await tester.pumpAndSettle();

    expect(find.text('Note not found'), findsOneWidget);
    await tester.tap(find.text('Create note'));
    await tester.pumpAndSettle();

    expect(requestedTitles, ['MissingNote']);
    expect(
      repository.requestedPaths,
      contains(_MissingLinkRepository.createdPath),
    );
    expect(provider.currentNote?.path, _MissingLinkRepository.createdPath);
    expect(find.text('MissingNote'), findsWidgets);
  });

  testWidgets('cancelling missing Wiki-link dialog does not create a note', (
    tester,
  ) async {
    final repository = _MissingLinkRepository();
    final requestedTitles = <String>[];
    final provider = await pumpEditor(
      tester,
      noteRepository: repository,
      initialPath: _MissingLinkRepository.sourcePath,
      onCreateMissingNote: (title) async {
        requestedTitles.add(title);
        return _MissingLinkRepository.createdPath;
      },
    );

    await tester.tap(find.text('Preview'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('MissingNote', findRichText: true));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(requestedTitles, isEmpty);
    expect(
      repository.requestedPaths,
      isNot(contains(_MissingLinkRepository.createdPath)),
    );
    expect(provider.currentNote?.path, _MissingLinkRepository.sourcePath);
  });
}

class _MissingLinkRepository implements NoteRepository {
  static const sourcePath = '/vault/Course/Source.md';
  static const createdPath = '/vault/Course/MissingNote.md';

  final requestedPaths = <String>[];

  @override
  List<String> extractWikilinks(String markdownContent) =>
      WikilinkParser.extract(markdownContent);

  @override
  Future<List<Note>> getAllNotes(String vaultRootPath) async => [
    Note(
      path: sourcePath,
      title: 'Source',
      content: '# Source\n\n[[MissingNote]]',
      outgoingLinks: const ['MissingNote'],
    ),
  ];

  @override
  Future<List<String>> getBacklinksForNote(
    String noteTitle,
    String vaultRootPath,
  ) async => const [];

  @override
  Future<Note> getNote(String filePath) async {
    requestedPaths.add(filePath);
    if (filePath == createdPath) {
      return Note(
        path: createdPath,
        title: 'MissingNote',
        content: '# MissingNote\n',
        outgoingLinks: const [],
      );
    }
    return Note(
      path: sourcePath,
      title: 'Source',
      content: '# Source\n\n[[MissingNote]]',
      outgoingLinks: const ['MissingNote'],
    );
  }

  @override
  Future<void> saveNote(Note note) async {}
}
