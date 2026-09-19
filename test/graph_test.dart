import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fptu_se_second_brain/contracts/ai_service.dart';
import 'package:fptu_se_second_brain/contracts/note_repository.dart';
import 'package:fptu_se_second_brain/contracts/vault_service.dart';
import 'package:fptu_se_second_brain/mocks/mock_ai_service.dart';
import 'package:fptu_se_second_brain/mocks/mock_note_repository.dart';
import 'package:fptu_se_second_brain/mocks/mock_vault_service.dart';
import 'package:fptu_se_second_brain/providers/ai_provider.dart';
import 'package:fptu_se_second_brain/providers/graph_provider.dart';
import 'package:fptu_se_second_brain/providers/note_provider.dart';
import 'package:fptu_se_second_brain/providers/theme_provider.dart';
import 'package:fptu_se_second_brain/providers/vault_provider.dart';
import 'package:fptu_se_second_brain/screens/graph/knowledge_graph_screen.dart';
import 'package:fptu_se_second_brain/screens/shell_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
      'Knowledge Graph: Display, hover persistence, drag, zoom controls, and click',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockVaultService = MockVaultService();
    final mockNoteRepository = MockNoteRepository();
    final mockAiService = MockAIService();

    final themeProvider = ThemeProvider();
    final vaultProvider = VaultProvider(vaultService: mockVaultService);
    final noteProvider = NoteProvider(noteRepository: mockNoteRepository);
    final graphProvider = GraphProvider(noteRepository: mockNoteRepository);
    final aiProvider = AIProvider(aiService: mockAiService);

    addTearDown(() {
      themeProvider.dispose();
      vaultProvider.dispose();
      noteProvider.dispose();
      aiProvider.dispose();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<VaultService>.value(value: mockVaultService),
          Provider<NoteRepository>.value(value: mockNoteRepository),
          Provider<AIService>.value(value: mockAiService),
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider<VaultProvider>.value(value: vaultProvider),
          ChangeNotifierProvider<NoteProvider>.value(value: noteProvider),
          ChangeNotifierProvider<AIProvider>.value(value: aiProvider),
          ChangeNotifierProxyProvider<NoteProvider, GraphProvider>(
            create: (_) => graphProvider,
            update: (_, np, gp) =>
                (gp ?? graphProvider)..updateFromNoteProvider(np),
          ),
        ],
        child: const MaterialApp(
          home: ShellScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Mở Vault
    await tester.runAsync(() async {
      await vaultProvider.openVault('/vault');
    });
    await tester.pumpAndSettle();

    // 2. Chuyển sang Knowledge Graph
    final graphIcon = find.byIcon(Icons.hub_outlined);
    expect(graphIcon, findsOneWidget);
    await tester.tap(graphIcon);
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 250));
    });
    await tester.pumpAndSettle();

    expect(find.text('Flutter Architecture'), findsOneWidget);
    expect(find.text('Provider Pattern'), findsOneWidget);
    expect(find.text('Agile Scrum Overview'), findsOneWidget);
    expect(find.text('Graph Algorithms'), findsOneWidget);
    expect(find.text('Quick Ideas'), findsOneWidget);
    expect(find.text('Daily Thoughts'), findsOneWidget);

    final flutterArchAvatarFinder = find.byKey(const ValueKey('node_avatar_flutter_architecture'));
    final rectBefore = tester.getRect(flutterArchAvatarFinder);

    // 3. KIỂM TRA HOVER: KHÔNG BỊ BIẾN MẤT
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(rectBefore.center);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Flutter Architecture'), findsOneWidget);
    expect(find.text('Provider Pattern'), findsOneWidget);
    expect(find.text('Agile Scrum Overview'), findsOneWidget);
    expect(find.text('Graph Algorithms'), findsOneWidget);
    expect(find.text('Quick Ideas'), findsOneWidget);
    expect(find.text('Daily Thoughts'), findsOneWidget);

    // 4. KIỂM TRA DRAG
    final providerPatternFinder = find.text('Provider Pattern');
    final providerPatternBefore = tester.getRect(providerPatternFinder);

    await tester.drag(flutterArchAvatarFinder, const Offset(120, 80));
    await tester.pumpAndSettle();

    final rectAfterDrag = tester.getRect(flutterArchAvatarFinder);
    expect(rectAfterDrag.center != rectBefore.center, true,
        reason: 'Node should have moved when dragged');

    final providerPatternAfter = tester.getRect(providerPatternFinder);
    expect(providerPatternAfter.center != providerPatternBefore.center, true,
        reason:
            'Connected node should automatically rebalance and adjust position when neighbor is dragged');

    // 5. KIỂM TRA ZOOM CONTROLS
    final zoomInBtn = find.byTooltip('Phóng to (+)');
    expect(zoomInBtn, findsOneWidget);
    await tester.tap(zoomInBtn);
    await tester.pumpAndSettle();

    final zoomOutBtn = find.byTooltip('Thu nhỏ (-)');
    expect(zoomOutBtn, findsOneWidget);
    await tester.tap(zoomOutBtn);
    await tester.pumpAndSettle();

    final fitBtn = find.byTooltip('Căn vừa màn hình (Fit to View)');
    expect(fitBtn, findsOneWidget);
    await tester.tap(fitBtn);
    await tester.pumpAndSettle();

    final resetBtn = find.byTooltip('Đặt lại tỷ lệ 100% (Reset)');
    expect(resetBtn, findsOneWidget);
    await tester.tap(resetBtn);
    await tester.pumpAndSettle();

    // 6. KIỂM TRA MOUSE SCROLL ZOOM: Không bị giật
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: const Offset(600, 400),
        scrollDelta: const Offset(0, 100),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Flutter Architecture'), findsOneWidget);

    // 7. KIỂM TRA CLICK NODE: Mở note (click vào node avatar)
    await tester.tap(flutterArchAvatarFinder);
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 250));
    });
    await tester.pumpAndSettle();


    final graphProviderInstance = tester
        .element(find.byType(KnowledgeGraphScreen))
        .read<GraphProvider>();
    expect(graphProviderInstance.activeNodeId, 'flutter_architecture');

    final noteProviderInstance =
        tester.element(find.byType(KnowledgeGraphScreen)).read<NoteProvider>();
    expect(noteProviderInstance.currentNote?.title, 'Flutter_Architecture');
  });
}
