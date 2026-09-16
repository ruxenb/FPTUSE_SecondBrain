import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fptu_se_second_brain/contracts/note_repository.dart';
import 'package:fptu_se_second_brain/mocks/mock_note_repository.dart';
import 'package:fptu_se_second_brain/providers/note_provider.dart';
import 'package:fptu_se_second_brain/screens/editor/note_editor_screen.dart';
import 'package:provider/provider.dart';

void main() {
  const flutterArchitecturePath =
      '/vault/PRM393_Mobile_Programming/Flutter_Architecture.md';

  Future<NoteProvider> pumpEditor(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = MockNoteRepository();
    final provider = NoteProvider(noteRepository: repository);
    addTearDown(provider.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<NoteRepository>.value(value: repository),
          ChangeNotifierProvider<NoteProvider>.value(value: provider),
        ],
        child: const MaterialApp(home: Scaffold(body: NoteEditorScreen())),
      ),
    );
    final openNote = provider.openNote(
      flutterArchitecturePath,
      vaultRoot: '/vault',
    );
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
}
