import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fptu_se_second_brain/main.dart';

void main() {
  testWidgets('FPTU Second Brain App smoke test on desktop view', (WidgetTester tester) async {
    // Giả lập kích thước màn hình Desktop chuẩn (1280x800)
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Khởi tạo app và verify render thành công
    await tester.pumpWidget(const FPTUSecondBrainApp());
    await tester.pumpAndSettle();

    // Verify thanh tiêu đề AppBar hiển thị
    expect(find.text('FPTU SE BRAIN'), findsOneWidget);
    // Verify màn hình Editor hiển thị bài note mẫu đã tải
    expect(find.text('Flutter_Architecture.md'), findsOneWidget);
    // Verify AI panel hiển thị
    expect(find.text('AI STUDY ASSISTANT'), findsOneWidget);
  });
}
