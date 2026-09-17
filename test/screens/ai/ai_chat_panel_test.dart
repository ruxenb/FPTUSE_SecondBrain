import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:fptu_se_second_brain/mocks/mock_ai_service.dart';
import 'package:fptu_se_second_brain/mocks/mock_note_repository.dart';
import 'package:fptu_se_second_brain/providers/ai_provider.dart';
import 'package:fptu_se_second_brain/providers/note_provider.dart';
import 'package:fptu_se_second_brain/screens/ai/ai_chat_panel.dart';

void main() {
  testWidgets('AI panel summarizes the currently opened note', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final noteProvider = NoteProvider(noteRepository: MockNoteRepository());
    await tester.runAsync(() async {
      await noteProvider.openNote(
        '/vault/PRM393_Mobile_Programming/Flutter_Architecture.md',
        vaultRoot: '/vault',
      );
    });
    final aiProvider = AIProvider(aiService: MockAIService());
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AIProvider>.value(value: aiProvider),
          ChangeNotifierProvider<NoteProvider>.value(value: noteProvider),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SizedBox(width: 360, child: AIChatPanel())),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('AI Assistant'), findsOneWidget);
    expect(find.text('Tóm tắt Note này'), findsOneWidget);
    expect(find.text('Tạo 3 câu Quiz'), findsOneWidget);

    await tester.tap(find.text('Tóm tắt Note này'));
    await tester.pump();
    expect(find.text('AI đang xử lý...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 850));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Tóm tắt: Flutter_Architecture'),
      findsOneWidget,
    );
    expect(aiProvider.messages, hasLength(1));
  });

  testWidgets('AI panel synchronizes note context after note switch', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final noteProvider = NoteProvider(noteRepository: MockNoteRepository());
    await tester.runAsync(() async {
      await noteProvider.openNote(
        '/vault/PRM393_Mobile_Programming/Flutter_Architecture.md',
        vaultRoot: '/vault',
      );
    });
    final aiProvider = AIProvider(aiService: MockAIService());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AIProvider>.value(value: aiProvider),
          ChangeNotifierProvider<NoteProvider>.value(value: noteProvider),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SizedBox(width: 360, child: AIChatPanel())),
        ),
      ),
    );
    await tester.pump();

    expect(
      aiProvider.activeNotePath,
      '/vault/PRM393_Mobile_Programming/Flutter_Architecture.md',
    );

    await tester.runAsync(() async {
      await noteProvider.openNote(
        '/vault/PRM393_Mobile_Programming/Provider_Pattern.md',
        vaultRoot: '/vault',
      );
    });
    await tester.pump();
    await tester.pump();

    expect(
      aiProvider.activeNotePath,
      '/vault/PRM393_Mobile_Programming/Provider_Pattern.md',
    );
  });
}
