import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/customer_home_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo tài khoản demo Khách hàng (customer@goship.vn / password)
  await AuthService.initMockUser();
  
  // Kiểm tra xem trước đó người dùng có chọn ghi nhớ đăng nhập hay không
  bool isLoggedIn = await AuthService.isLogin();

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoShip Client',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange.shade800,
          primary: Colors.orange.shade800,
        ),
      ),
      home: isLoggedIn ? const CustomerHomeScreen() : const LoginScreen(),
    );
  }
}
