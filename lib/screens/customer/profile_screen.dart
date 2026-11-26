import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/customer_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../widgets/not_logged_in_view.dart';
import '../../widgets/user_avatar.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String _notUpdated = 'Chưa cập nhật';

  /// Lắng nghe trạng thái đăng nhập liên tục (không chỉ kiểm tra 1 lần lúc mở trang),
  /// để khi phiên đăng nhập mất (đăng xuất, tài khoản bị khoá, token hết hạn...)
  /// trang tự chuyển sang màn "Bạn chưa đăng nhập".
  late final Stream<User?> _authStream;

  /// Stream hồ sơ được cache theo uid, tránh tạo listener Firestore mới mỗi lần build.
  String? _streamUid;
  Stream<CustomerModel?>? _customerStream;

  /// Đang hỏi máy chủ xem tài khoản còn hợp lệ không (lúc vừa mở trang).
  bool _verifying = true;

  /// Tài khoản đã bị Disable / Delete trên Firebase Console (đã tự đăng xuất).
  bool _accountRevoked = false;

  @override
  void initState() {
    super.initState();
    _authStream = AuthRepository().authStateChanges;
    _verifySession();
  }

  /// Firebase lưu phiên đăng nhập trên máy (token sống tới 1 giờ) nên không tự
  /// biết khi tài khoản bị vô hiệu hoá / xoá trên Console. Mỗi lần mở trang,
  /// hỏi lại máy chủ; nếu không còn hợp lệ, repository sẽ đăng xuất và
  /// authStateChanges phát `null` -> hiện màn "Bạn chưa đăng nhập".
  Future<void> _verifySession() async {
    final status = await AuthRepository().verifyCurrentUser();
    if (!mounted) return;
    setState(() {
      _verifying = false;
      _accountRevoked = status == SessionStatus.invalid;
    });
  }

  Stream<CustomerModel?> _customerStreamFor(User user) {
    if (_streamUid != user.uid || _customerStream == null) {
      _streamUid = user.uid;
      // Tạo document nếu chưa có (chỉ chạy 1 lần cho mỗi uid, và chỉ sau khi
      // đã xác minh tài khoản -> không tạo lại document cho tài khoản đã bị xoá).
      CustomerRepository().ensureCustomerDoc(user.uid, email: user.email);
      _customerStream = CustomerRepository().watchCustomer(user.uid);
    }
    return _customerStream!;
  }

  void _logout() async {
    await AuthRepository().logout();
    if (!mounted) return;
    NotLoggedInView.goToLogin(context);
  }

  void _goToLogin() => NotLoggedInView.goToLogin(context);

  String _orNotUpdated(String value) => value.isNotEmpty ? value : _notUpdated;

  Widget _infoTile(IconData icon, String title, String value) {
    final isEmpty = value.isEmpty;
    return ListTile(
      leading: Icon(icon, color: Colors.orange),
      title: Text(title),
      subtitle: Text(
        _orNotUpdated(value),
        style: isEmpty ? TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.orange.shade800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<User?>(
        stream: _authStream,
        builder: (context, authSnapshot) {
          if (_verifying ||
              (authSnapshot.connectionState == ConnectionState.waiting && !authSnapshot.hasData)) {
            return const Center(child: CircularProgressIndicator());
          }

          final authUser = authSnapshot.data;
          if (authUser == null) {
            return _accountRevoked
                ? NotLoggedInView(
                    onLogin: _goToLogin,
                    message: 'Tài khoản của bạn đã bị vô hiệu hoá hoặc không còn tồn tại. '
                        'Vui lòng đăng nhập bằng tài khoản khác hoặc liên hệ hỗ trợ.',
                  )
                : NotLoggedInView(onLogin: _goToLogin);
          }

          return _buildProfile(authUser, primaryColor);
        },
      ),
    );
  }

  Widget _buildProfile(User authUser, Color primaryColor) {
    return StreamBuilder<CustomerModel?>(
        stream: _customerStreamFor(authUser),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // Firestore từ chối đọc (thường do phiên đăng nhập không còn hợp lệ)
            // -> mời đăng nhập lại thay vì hiện lỗi thô.
            final error = snapshot.error;
            if (error is FirebaseException &&
                (error.code == 'permission-denied' || error.code == 'unauthenticated')) {
              return NotLoggedInView(
                onLogin: _goToLogin,
                message: 'Phiên đăng nhập đã hết hạn hoặc không hợp lệ. Vui lòng đăng nhập lại.',
              );
            }
            return Center(child: Text('Đã xảy ra lỗi: $error'));
          }

          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text("Không tải được dữ liệu người dùng."));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                UserAvatar(avatar: user.avatar, name: user.name, radius: 50),
                const SizedBox(height: 12),
                Text(
                  user.name.isNotEmpty ? user.name : 'Khách hàng',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(user.email, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                const SizedBox(height: 24),

                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      _infoTile(Icons.phone, 'Số điện thoại', user.phone),
                      const Divider(height: 1),
                      _infoTile(Icons.people, 'Giới tính', user.gender),
                      const Divider(height: 1),
                      _infoTile(Icons.location_city, 'Tỉnh / Thành phố', user.city),
                      const Divider(height: 1),
                      _infoTile(Icons.home, 'Địa chỉ', user.address),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)),
                    );
                  },
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text('Chỉnh sửa thông tin', style: TextStyle(color: Colors.white, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('Đăng xuất', style: TextStyle(color: Colors.red, fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          );
        },
    );
  }
}
