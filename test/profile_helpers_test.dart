import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goship/constants/vn_provinces.dart';
import 'package:goship/widgets/user_avatar.dart';

void main() {
  group('VnProvinces', () {
    test('có đúng 34 đơn vị, không trùng lặp', () {
      expect(VnProvinces.cities.length, 6);
      expect(VnProvinces.provinces.length, 28);
      expect(VnProvinces.all.length, 34);
      expect(VnProvinces.all.toSet().length, 34);
    });

    test('bảng bỏ dấu khớp độ dài', () {
      expect(VnProvinces.removeDiacritics('Đà Nẵng'), 'da nang');
      expect(VnProvinces.removeDiacritics('TP. Hồ Chí Minh'), 'tp. ho chi minh');
      expect(VnProvinces.removeDiacritics('Quảng Ngãi'), 'quang ngai');
      expect(VnProvinces.removeDiacritics('Khánh Hòa'), 'khanh hoa');
    });

    test('normalize xử lý giá trị rỗng / không hợp lệ', () {
      expect(VnProvinces.normalize(null), isNull);
      expect(VnProvinces.normalize(''), isNull);
      expect(VnProvinces.normalize('Unknow'), isNull);
    });

    test('normalize giữ nguyên tên hợp lệ và chuyển tên cũ', () {
      expect(VnProvinces.normalize('TP. Hồ Chí Minh'), 'TP. Hồ Chí Minh');
      expect(VnProvinces.normalize(' hà nội '), 'Hà Nội');
      expect(VnProvinces.normalize('Tỉnh Nghệ An'), 'Nghệ An');
      expect(VnProvinces.normalize('Bình Dương'), 'TP. Hồ Chí Minh');
      expect(VnProvinces.normalize('Thừa Thiên Huế'), 'Huế');
      expect(VnProvinces.normalize('Quảng Nam'), 'Đà Nẵng');
      expect(VnProvinces.normalize('Kiên Giang'), 'An Giang');
    });

    test('mọi alias đều trỏ tới đơn vị hợp lệ', () {
      for (final old in ['hà giang', 'yên bái', 'bắc kạn', 'vĩnh phúc', 'bắc giang', 'thái bình',
          'hải dương', 'nam định', 'quảng bình', 'kon tum', 'bình định', 'ninh thuận', 'đắk nông',
          'phú yên', 'bà rịa - vũng tàu', 'bình phước', 'long an', 'sóc trăng', 'bến tre',
          'tiền giang', 'bạc liêu']) {
        expect(VnProvinces.all, contains(VnProvinces.normalize(old)), reason: old);
      }
    });
  });

  group('UserAvatar', () {
    Future<void> pump(WidgetTester tester, Widget w) =>
        tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: w))));

    testWidgets('avatar rỗng -> hiện chữ cái đầu', (tester) async {
      await pump(tester, const UserAvatar(avatar: '', name: 'an nguyen'));
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('avatar rỗng, không tên -> hiện icon', (tester) async {
      await pump(tester, const UserAvatar(avatar: ''));
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('data URI base64 -> dùng MemoryImage', (tester) async {
      final encoded = UserAvatar.encode(Uint8List.fromList([1, 2, 3, 4]));
      expect(encoded.startsWith('data:image/jpeg;base64,'), isTrue);
      await pump(tester, UserAvatar(avatar: encoded, name: 'B'));
      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.backgroundImage, isA<MemoryImage>());
    });

    testWidgets('chuỗi hỏng -> fallback, không crash', (tester) async {
      await pump(tester, const UserAvatar(avatar: 'data:image/jpeg;base64,@@@', name: 'C'));
      expect(find.text('C'), findsOneWidget);
    });
  });
}
