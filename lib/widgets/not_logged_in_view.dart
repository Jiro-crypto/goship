import 'package:flutter/material.dart';

import '../screens/login_screen.dart';

/// Màn hình thông báo "chưa đăng nhập" kèm nút Đăng nhập, dùng chung cho các
/// trang yêu cầu tài khoản (Trang chủ khách hàng, Hồ sơ cá nhân, ...).
class NotLoggedInView extends StatelessWidget {
  /// Hành động khi bấm nút Đăng nhập. Mặc định dùng [goToLogin].
  /// Cho phép truyền từ ngoài vào để dễ viết test.
  final VoidCallback? onLogin;

  final String message;

  const NotLoggedInView({
    super.key,
    this.onLogin,
    this.message = 'Vui lòng đăng nhập để xem và quản lý thông tin của bạn.',
  });

  /// Về trang Đăng nhập và xoá toàn bộ các màn trước đó, tránh bấm Back
  /// quay lại trang yêu cầu đăng nhập.
  static void goToLogin(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.orange.shade800;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: Colors.orange.shade50,
              child: Icon(Icons.lock_outline, size: 44, color: primaryColor),
            ),
            const SizedBox(height: 20),
            const Text(
              'Bạn chưa đăng nhập',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onLogin ?? () => goToLogin(context),
                icon: const Icon(Icons.login, color: Colors.white),
                label: const Text(
                  'ĐĂNG NHẬP',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
