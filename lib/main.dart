import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // File này được sinh tự động khi thêm Firebase
import 'screens/login_screen.dart';
import 'screens/customer_home_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Kiểm tra trạng thái đăng nhập Firebase
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