import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fptu_se_second_brain/main.dart';

void main() {
  testWidgets('FPTU Second Brain App shows the Vault Explorer', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const FPTUSecondBrainApp());
    await tester.pumpAndSettle();

    // Verify title
    expect(
      find.text('FPTU SE SECOND BRAIN (ARCHITECTURAL TEMPLATE)'),
      findsOneWidget,
    );
    // Verify the completed Vault column and the remaining module placeholders.
    expect(find.text('EXPLORER'), findsOneWidget);
    expect(find.text('Chưa có Vault nào được mở'), findsOneWidget);
    expect(find.text('Member 2 (Markdown Editor & Note)'), findsOneWidget);
    expect(find.text('Member 3 (AI Assistant)'), findsOneWidget);
  });
}
