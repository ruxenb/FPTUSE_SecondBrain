import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fptu_se_second_brain/main.dart';

void main() {
  testWidgets('FPTU Second Brain App template smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const FPTUSecondBrainApp());
    await tester.pumpAndSettle();

    // Verify title
    expect(find.text('FPTU SE SECOND BRAIN'), findsOneWidget);
    // Verify 3 member columns
    expect(find.text('Vault & Filesystem'), findsOneWidget);
    expect(find.text('Markdown Editor & Note'), findsOneWidget);
    expect(find.text('AI Assistant'), findsOneWidget);
  });
}
