import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goship/main.dart';

void main() {
  testWidgets('Verify Login Screen displays successfully', (WidgetTester tester) async {
    // Build app và kích hoạt frame đầu tiên
    await tester.pumpWidget(const MyApp(isLoggedIn: false));

    // Kiểm tra xem nhãn "GOSHIP" và nút "ĐĂNG NHẬP" có hiển thị hay không
    expect(find.text('GOSHIP'), findsOneWidget);
    expect(find.text('ĐĂNG NHẬP'), findsOneWidget);
  });
}
