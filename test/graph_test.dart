import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fptu_se_second_brain/main.dart';
import 'package:fptu_se_second_brain/providers/graph_provider.dart';
import 'package:fptu_se_second_brain/providers/note_provider.dart';
import 'package:fptu_se_second_brain/screens/graph/knowledge_graph_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Knowledge Graph: Display, hover persistence, drag, zoom controls, and click',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const FPTUSecondBrainApp());
    await tester.pumpAndSettle();

    // 1. Mở Vault
    final vaultBtn = find.text('Test MockVaultService');
    expect(vaultBtn, findsOneWidget);
    await tester.tap(vaultBtn);
    await tester.pumpAndSettle();

    // 2. Chuyển sang Knowledge Graph
    final graphIcon = find.byIcon(Icons.hub_outlined);
    expect(graphIcon, findsOneWidget);
    await tester.tap(graphIcon);
    await tester.pumpAndSettle();

    // Kiểm tra hiển thị đủ các node từ MockNoteRepository (bao gồm cả node rời Daily Thoughts)
    expect(find.text('Flutter Architecture'), findsOneWidget);
    expect(find.text('Provider Pattern'), findsOneWidget);
    expect(find.text('Agile Scrum Overview'), findsOneWidget);
    expect(find.text('Graph Algorithms'), findsOneWidget);
    expect(find.text('Quick Ideas'), findsOneWidget);
    expect(find.text('Daily Thoughts'), findsOneWidget);

    final flutterArchFinder = find.text('Flutter Architecture');
    final rectBefore = tester.getRect(flutterArchFinder);

    // 3. KIỂM TRA HOVER: KHÔNG BỊ BIẾN MẤT
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(rectBefore.center);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Đảm bảo sau khi hover, TẤT CẢ các node vẫn tồn tại nguyên vẹn!
    expect(find.text('Flutter Architecture'), findsOneWidget);
    expect(find.text('Provider Pattern'), findsOneWidget);
    expect(find.text('Agile Scrum Overview'), findsOneWidget);
    expect(find.text('Graph Algorithms'), findsOneWidget);
    expect(find.text('Quick Ideas'), findsOneWidget);
    expect(find.text('Daily Thoughts'), findsOneWidget);

    // 4. KIỂM TRA DRAG: Kéo thả node và các node liên kết tự động cân bằng lại
    final providerPatternFinder = find.text('Provider Pattern');
    final providerPatternBefore = tester.getRect(providerPatternFinder);

    await tester.drag(flutterArchFinder, const Offset(120, 80));
    await tester.pumpAndSettle();

    final rectAfterDrag = tester.getRect(flutterArchFinder);
    expect(rectAfterDrag.center != rectBefore.center, true,
        reason: 'Node should have moved when dragged');

    final providerPatternAfter = tester.getRect(providerPatternFinder);
    expect(providerPatternAfter.center != providerPatternBefore.center, true,
        reason: 'Connected node should automatically rebalance and adjust position when neighbor is dragged');

    // 5. KIỂM TRA ZOOM CONTROLS
    // Zoom In (+)
    final zoomInBtn = find.byTooltip('Phóng to (+)');
    expect(zoomInBtn, findsOneWidget);
    await tester.tap(zoomInBtn);
    await tester.pumpAndSettle();

    // Zoom Out (-)
    final zoomOutBtn = find.byTooltip('Thu nhỏ (-)');
    expect(zoomOutBtn, findsOneWidget);
    await tester.tap(zoomOutBtn);
    await tester.pumpAndSettle();

    // Fit to View
    final fitBtn = find.byTooltip('Căn vừa màn hình (Fit to View)');
    expect(fitBtn, findsOneWidget);
    await tester.tap(fitBtn);
    await tester.pumpAndSettle();

    // Reset View
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

    // 7. KIỂM TRA CLICK NODE: Mở note
    await tester.tap(flutterArchFinder);
    await tester.pumpAndSettle();

    final graphProvider = tester.element(find.byType(KnowledgeGraphScreen)).read<GraphProvider>();
    expect(graphProvider.activeNodeId, 'flutter_architecture');

    final noteProvider = tester.element(find.byType(KnowledgeGraphScreen)).read<NoteProvider>();
    expect(noteProvider.currentNote?.title, 'Flutter_Architecture');
  });
}
