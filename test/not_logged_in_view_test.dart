import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goship/widgets/not_logged_in_view.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));

  group('NotLoggedInView', () {
    testWidgets('hiển thị thông báo chưa đăng nhập và nút Đăng nhập', (tester) async {
      await pump(tester, NotLoggedInView(onLogin: () {}));

      expect(find.text('Bạn chưa đăng nhập'), findsOneWidget);
      expect(find.text('Vui lòng đăng nhập để xem và quản lý thông tin của bạn.'), findsOneWidget);
      expect(find.text('ĐĂNG NHẬP'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('bấm nút Đăng nhập gọi đúng callback onLogin 1 lần', (tester) async {
      var tapCount = 0;
      await pump(tester, NotLoggedInView(onLogin: () => tapCount++));

      await tester.tap(find.text('ĐĂNG NHẬP'));
      await tester.pump();

      expect(tapCount, 1);
    });

    testWidgets('hiển thị thông báo tuỳ chỉnh (vd: phiên đăng nhập hết hạn)', (tester) async {
      const message = 'Phiên đăng nhập đã hết hạn hoặc không hợp lệ. Vui lòng đăng nhập lại.';
      await pump(tester, NotLoggedInView(onLogin: () {}, message: message));

      expect(find.text(message), findsOneWidget);
      expect(find.text('ĐĂNG NHẬP'), findsOneWidget);
    });

    testWidgets('không bị tràn giao diện trên màn hình nhỏ', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pump(tester, NotLoggedInView(onLogin: () {}));

      expect(tester.takeException(), isNull);
      expect(find.text('ĐĂNG NHẬP'), findsOneWidget);
    });
  });
}
