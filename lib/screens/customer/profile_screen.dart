import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/preference_service.dart';
import '../../services/auth_service.dart';
import 'edit_profile_screen.dart';
import '../login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() async {
    final u = await PreferenceService.getUser();
    setState(() {
      _user = u ?? UserModel(
        fullName: "Khách Hàng GoShip",
        email: "customer@goship.vn",
        phone: "0909123456",
        password: "password",
        avatar: "https://cdn-icons-png.flaticon.com/512/3135/3135715.png",
        gender: "Nam",
        city: "TP. Hồ Chí Minh",
      );
      _isLoading = false;
    });
  }

  void _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.orange.shade800;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hồ sơ cá nhân'), backgroundColor: primaryColor),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.orange.shade100,
              backgroundImage: NetworkImage(_user!.avatar),
            ),
            const SizedBox(height: 12),
            Text(_user!.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(_user!.email, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            const SizedBox(height: 24),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.phone, color: Colors.orange),
                    title: const Text('Số điện thoại'),
                    subtitle: Text(_user!.phone),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.people, color: Colors.orange),
                    title: const Text('Giới tính'),
                    subtitle: Text(_user!.gender.isNotEmpty ? _user!.gender : "Nam"),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.location_city, color: Colors.orange),
                    title: const Text('Thành phố'),
                    subtitle: Text(_user!.city.isNotEmpty ? _user!.city : "TP. Hồ Chí Minh"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditProfileScreen(user: _user!)),
                );
                if (updated == true) _loadUser();
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
      ),
    );
  }
}
