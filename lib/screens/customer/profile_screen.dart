import 'package:flutter/material.dart';
import '../../models/customer_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../widgets/user_avatar.dart';
import 'edit_profile_screen.dart';
import '../login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String _notUpdated = 'Chưa cập nhật';

  late String _currentUid;
  late final Stream<CustomerModel?> _customerStream;

  @override
  void initState() {
    super.initState();
    _currentUid = AuthRepository().getCurrentUid() ?? '';
    if (_currentUid.isNotEmpty) {
      CustomerRepository().ensureCustomerDoc(
        _currentUid,
        email: AuthRepository().getCurrentEmail(),
      );
    }
    // Tạo stream 1 lần, tránh mỗi lần build lại tạo listener Firestore mới.
    _customerStream = CustomerRepository().watchCustomer(_currentUid);
  }

  void _logout() async {
    await AuthRepository().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

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

    if (_currentUid.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hồ sơ cá nhân'), backgroundColor: primaryColor),
        body: const Center(child: Text("Không tìm thấy người dùng hiện tại.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<CustomerModel?>(
        stream: _customerStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Đã xảy ra lỗi: ${snapshot.error}'));
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
        }
      ),
    );
  }
}
