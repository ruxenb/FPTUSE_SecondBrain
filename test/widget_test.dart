import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fptu_se_second_brain/main.dart';

void main() {
  testWidgets('FPTU Second Brain App smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const FPTUSecondBrainApp());
    await tester.pumpAndSettle();

    expect(
      find.text('FPTU SE SECOND BRAIN (ARCHITECTURAL TEMPLATE)'),
      findsOneWidget,
    );
    expect(find.text('Member 1 (Vault & Filesystem)'), findsOneWidget);
    expect(find.text('Member 2 (Markdown Editor & Note)'), findsOneWidget);
    expect(find.text('AI Assistant'), findsOneWidget);
    expect(find.text('Tóm tắt Note này'), findsOneWidget);
    expect(find.text('Tạo 3 câu Quiz'), findsOneWidget);
  });
}
